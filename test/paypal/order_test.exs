defmodule Paypal.OrderTest do
  use Paypal.Case
  alias Paypal.Auth.Worker, as: AuthWorker
  alias Paypal.Order

  setup %{bypass: bypass} do
    Bypass.stub(bypass, "POST", "/v1/oauth2/token", fn %Plug.Conn{} = conn ->
      response(conn, 200, %{
        "access_token" => "ACCESSTOKEN",
        "app_id" => "APP-ID",
        "expires_in" => 32_400,
        "nonce" => "2024-05-08T22:22:22NONCE",
        "scope" =>
          "https://uri.paypal.com/services/payments/futurepayments https://uri.paypal.com/services/invoicing https://uri.paypal.com/services/vault/payment-tokens/read https://uri.paypal.com/services/disputes/read-buyer https://uri.paypal.com/services/payments/realtimepayment https://uri.paypal.com/services/disputes/update-seller https://uri.paypal.com/services/payments/payment/authcapture openid https://uri.paypal.com/services/disputes/read-seller Braintree:Vault https://uri.paypal.com/services/payments/refund https://api.paypal.com/v1/vault/credit-card https://api.paypal.com/v1/payments/.* https://uri.paypal.com/payments/payouts https://uri.paypal.com/services/vault/payment-tokens/readwrite https://api.paypal.com/v1/vault/credit-card/.* https://uri.paypal.com/services/subscriptions https://uri.paypal.com/services/applications/webhooks",
        "token_type" => "Bearer"
      })
    end)

    # Ensure auth worker is running and has token
    case Paypal.Auth.get_token() do
      {:ok, "ACCESSTOKEN"} ->
        :ok

      _ ->
        AuthWorker.refresh()
        assert "ACCESSTOKEN" == Paypal.Auth.get_token!()
    end

    :ok
  end

  describe "patch/2" do
    test "successfully patches an order with valid data", %{bypass: bypass} do
      order_id = "5UY53123AX394662R"

      patch_data = [
        %{
          op: "replace",
          path: "/purchase_units/@reference_id=='default'/amount",
          value: %{
            currency_code: "EUR",
            value: "15.00"
          }
        }
      ]

      Bypass.expect_once(bypass, "PATCH", "/v2/checkout/orders/#{order_id}", fn conn ->
        response(conn, 204, nil)
      end)

      assert :ok == Order.patch(order_id, patch_data)
    end

    test "handles API error when patching", %{bypass: bypass} do
      order_id = "INVALID_ORDER"

      patch_data = [
        %{
          op: "replace",
          path: "/purchase_units/@reference_id=='default'/amount",
          value: %{
            currency_code: "EUR",
            value: "15.00"
          }
        }
      ]

      Bypass.expect_once(bypass, "PATCH", "/v2/checkout/orders/#{order_id}", fn conn ->
        response(conn, 404, %{
          "name" => "INVALID_REQUEST",
          "message" => "Request is not well-formed, syntactically incorrect, or violates schema.",
          "debug_id" => "debug_id_here",
          "details" => [
            %{
              "field" => "order_id",
              "value" => order_id,
              "location" => "path",
              "issue" => "INVALID_ORDER_ID",
              "description" => "The specified order ID is invalid."
            }
          ]
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "INVALID_REQUEST"}} =
               Order.patch(order_id, patch_data)
    end
  end

  describe "confirm/2" do
    test "successfully confirms payment source", %{bypass: bypass} do
      order_id = "5UY53123AX394662R"

      payment_source = %{
        paypal: %{
          experience_context: %{
            brand_name: "EXAMPLE INC",
            locale: "en-US",
            landing_page: "LOGIN",
            shipping_preference: "SET_PROVIDED_ADDRESS",
            user_action: "PAY_NOW",
            return_url: "https://example.com/returnUrl",
            cancel_url: "https://example.com/cancelUrl"
          }
        }
      }

      Bypass.expect_once(
        bypass,
        "POST",
        "/v2/checkout/orders/#{order_id}/confirm-payment-source",
        fn conn ->
          response(conn, 200, %{
            "id" => order_id,
            "status" => "APPROVED",
            "payment_source" => %{
              "paypal" => %{
                "name" => %{
                  "given_name" => "Firstname",
                  "surname" => "Lastname"
                },
                "email_address" => "buyer@example.com",
                "account_id" => "QYR5Z8XDVJNXQ"
              }
            }
          })
        end
      )

      expected_result = %Paypal.Order.Confirm{
        id: order_id,
        status: :approved,
        payment_source: %{
          "paypal" => %{
            "name" => %{
              "given_name" => "Firstname",
              "surname" => "Lastname"
            },
            "email_address" => "buyer@example.com",
            "account_id" => "QYR5Z8XDVJNXQ"
          }
        }
      }

      assert {:ok, expected_result} == Order.confirm(order_id, payment_source)
    end

    test "handles API error when confirming payment source", %{bypass: bypass} do
      order_id = "5UY53123AX394662R"

      payment_source = %{
        paypal: %{}
      }

      Bypass.expect_once(
        bypass,
        "POST",
        "/v2/checkout/orders/#{order_id}/confirm-payment-source",
        fn conn ->
          response(conn, 422, %{
            "name" => "UNPROCESSABLE_ENTITY",
            "message" =>
              "The requested action could not be performed, semantically incorrect, or failed business validation.",
            "debug_id" => "debug_id_here",
            "details" => [
              %{
                "field" => "payment_source",
                "location" => "body",
                "issue" => "MISSING_REQUIRED_PARAMETER",
                "description" => "A required field/parameter is missing"
              }
            ]
          })
        end
      )

      assert {:error, %Paypal.Common.Error{name: "UNPROCESSABLE_ENTITY"}} =
               Order.confirm(order_id, payment_source)
    end
  end

  describe "track/2" do
    test "successfully adds tracking information", %{bypass: bypass} do
      order_id = "5UY53123AX394662R"

      tracker_data = %{
        transaction_id: "8AC171449X0333500",
        tracking_number: "1Z999AA1234567890",
        carrier: "UPS",
        capture_id: "8AC171449X0333500",
        notify_payer: true
      }

      Bypass.expect_once(bypass, "POST", "/v2/checkout/orders/#{order_id}/track", fn conn ->
        response(conn, 204, nil)
      end)

      assert :ok == Order.track(order_id, tracker_data)
    end

    test "handles API error when adding tracking", %{bypass: bypass} do
      order_id = "5UY53123AX394662R"

      tracker_data = %{
        transaction_id: "INVALID_TRANSACTION",
        tracking_number: "1Z999AA1234567890",
        carrier: "UPS",
        capture_id: "8AC171449X0333500",
        notify_payer: true
      }

      Bypass.expect_once(bypass, "POST", "/v2/checkout/orders/#{order_id}/track", fn conn ->
        response(conn, 404, %{
          "name" => "RESOURCE_NOT_FOUND",
          "message" => "The specified resource does not exist.",
          "debug_id" => "debug_id_here",
          "details" => [
            %{
              "field" => "transaction_id",
              "value" => "INVALID_TRANSACTION",
              "location" => "body",
              "issue" => "INVALID_TRANSACTION_ID",
              "description" => "The transaction ID is invalid."
            }
          ]
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "RESOURCE_NOT_FOUND"}} =
               Order.track(order_id, tracker_data)
    end
  end

  describe "callback/2" do
    test "successfully updates order with callback data", %{bypass: bypass} do
      order_id = "5UY53123AX394662R"

      callback_data = %{
        callback_url: "https://example.com/callback",
        callback_timeout: "5",
        callback_delay: "2"
      }

      Bypass.expect_once(
        bypass,
        "POST",
        "/v2/checkout/orders/#{order_id}/order-update-callback",
        fn conn ->
          response(conn, 200, %{
            "id" => order_id,
            "status" => "APPROVED",
            "links" => [
              %{
                "href" => "https://api.sandbox.paypal.com/v2/checkout/orders/#{order_id}",
                "rel" => "self",
                "method" => "GET"
              }
            ]
          })
        end
      )

      expected_result = %Paypal.Order.Callback{
        id: order_id,
        status: :approved,
        links: [
          %Paypal.Common.Link{
            href: "https://api.sandbox.paypal.com/v2/checkout/orders/#{order_id}",
            rel: "self",
            method: :get
          }
        ]
      }

      assert {:ok, expected_result} == Order.callback(order_id, callback_data)
    end

    test "handles API error when updating callback", %{bypass: bypass} do
      order_id = "5UY53123AX394662R"

      callback_data = %{
        callback_url: "invalid-url",
        callback_timeout: "5",
        callback_delay: "2"
      }

      Bypass.expect_once(
        bypass,
        "POST",
        "/v2/checkout/orders/#{order_id}/order-update-callback",
        fn conn ->
          response(conn, 400, %{
            "name" => "INVALID_REQUEST",
            "message" =>
              "Request is not well-formed, syntactically incorrect, or violates schema.",
            "debug_id" => "debug_id_here",
            "details" => [
              %{
                "field" => "callback_url",
                "value" => "invalid-url",
                "location" => "body",
                "issue" => "INVALID_URL",
                "description" => "The callback URL is invalid."
              }
            ]
          })
        end
      )

      assert {:error, %Paypal.Common.Error{name: "INVALID_REQUEST"}} =
               Order.callback(order_id, callback_data)
    end
  end
end
