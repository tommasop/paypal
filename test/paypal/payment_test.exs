defmodule Paypal.PaymentTest do
  use Paypal.Case
  alias Paypal.Auth.Worker, as: AuthWorker
  alias Paypal.Payment

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

  describe "reauthorize/2" do
    test "successfully reauthorizes an authorization with valid data", %{bypass: bypass} do
      authorization_id = "5UY53123AX394662R"

      reauthorize_data = %{
        amount: %{
          currency_code: "USD",
          value: "100.00"
        }
      }

      Bypass.expect_once(
        bypass,
        "POST",
        "/v2/payments/authorizations/#{authorization_id}/reauthorize",
        fn conn ->
          response(conn, 201, %{
            "id" => authorization_id,
            "status" => "CREATED",
            "amount" => %{
              "currency_code" => "USD",
              "value" => "100.00"
            },
            "create_time" => "2024-10-10T10:06:03-07:00",
            "update_time" => "2024-10-10T10:06:19-07:00",
            "links" => [
              %{
                "href" =>
                  "https://api-m.paypal.com/v2/payments/authorizations/#{authorization_id}",
                "rel" => "self",
                "method" => "GET"
              }
            ]
          })
        end
      )

      assert {:ok, %Paypal.Payment.Info{id: ^authorization_id, status: :created}} =
               Payment.reauthorize(authorization_id, reauthorize_data)
    end

    test "successfully reauthorizes an authorization with empty body", %{bypass: bypass} do
      authorization_id = "5UY53123AX394662R"

      Bypass.expect_once(
        bypass,
        "POST",
        "/v2/payments/authorizations/#{authorization_id}/reauthorize",
        fn conn ->
          response(conn, 201, %{
            "id" => authorization_id,
            "status" => "CREATED",
            "amount" => %{
              "currency_code" => "USD",
              "value" => "100.00"
            },
            "create_time" => "2024-10-10T10:06:03-07:00",
            "update_time" => "2024-10-10T10:06:19-07:00",
            "links" => [
              %{
                "href" =>
                  "https://api-m.paypal.com/v2/payments/authorizations/#{authorization_id}",
                "rel" => "self",
                "method" => "GET"
              }
            ]
          })
        end
      )

      assert {:ok, %Paypal.Payment.Info{id: ^authorization_id, status: :created}} =
               Payment.reauthorize(authorization_id)
    end

    test "handles API error when reauthorizing", %{bypass: bypass} do
      authorization_id = "INVALID_AUTH"

      reauthorize_data = %{
        amount: %{
          currency_code: "USD",
          value: "100.00"
        }
      }

      Bypass.expect_once(
        bypass,
        "POST",
        "/v2/payments/authorizations/#{authorization_id}/reauthorize",
        fn conn ->
          response(conn, 404, %{
            "name" => "INVALID_REQUEST",
            "message" =>
              "Request is not well-formed, syntactically incorrect, or violates schema.",
            "debug_id" => "debug_id_here",
            "details" => [
              %{
                "field" => "authorization_id",
                "value" => authorization_id,
                "location" => "path",
                "issue" => "INVALID_AUTHORIZATION_ID",
                "description" => "The specified authorization ID is invalid."
              }
            ]
          })
        end
      )

      assert {:error, %Paypal.Common.Error{name: "INVALID_REQUEST"}} =
               Payment.reauthorize(authorization_id, reauthorize_data)
    end
  end

  describe "capture/2" do
    test "successfully captures an authorization with empty body", %{bypass: bypass} do
      authorization_id = "5UY53123AX394662R"

      Bypass.expect_once(
        bypass,
        "POST",
        "/v2/payments/authorizations/#{authorization_id}/capture",
        fn conn ->
          response(conn, 201, %{
            "id" => "8AC10462XH6416514",
            "status" => "COMPLETED",
            "amount" => %{
              "currency_code" => "USD",
              "value" => "100.00"
            },
            "final_capture" => true,
            "create_time" => "2024-10-23T20:55:19Z",
            "update_time" => "2024-10-23T20:55:19Z",
            "links" => [
              %{
                "href" =>
                  "https://api-m.sandbox.paypal.com/v2/payments/captures/8AC10462XH6416514",
                "rel" => "self",
                "method" => "GET"
              }
            ]
          })
        end
      )

      assert {:ok, %Paypal.Payment.Captured{id: "8AC10462XH6416514", status: :completed}} =
               Payment.capture(authorization_id)
    end

    test "successfully captures an authorization with full parameters", %{bypass: bypass} do
      authorization_id = "5UY53123AX394662R"

      capture_data = %{
        invoice_id: "OrderInvoice-10_10_2024_12_58_20_pm",
        note_to_payer: "Thank you for your payment",
        final_capture: true,
        soft_descriptor: "PAYPAL *TEST STORE",
        amount: %{
          currency_code: "USD",
          value: "100.00"
        }
      }

      Bypass.expect_once(
        bypass,
        "POST",
        "/v2/payments/authorizations/#{authorization_id}/capture",
        fn conn ->
          response(conn, 201, %{
            "id" => "8AC10462XH6416514",
            "status" => "COMPLETED",
            "amount" => %{
              "currency_code" => "USD",
              "value" => "100.00"
            },
            "final_capture" => true,
            "invoice_id" => "OrderInvoice-10_10_2024_12_58_20_pm",
            "create_time" => "2024-10-23T20:55:19Z",
            "update_time" => "2024-10-23T20:55:19Z",
            "links" => [
              %{
                "href" =>
                  "https://api-m.sandbox.paypal.com/v2/payments/captures/8AC10462XH6416514",
                "rel" => "self",
                "method" => "GET"
              }
            ]
          })
        end
      )

      assert {:ok, %Paypal.Payment.Captured{id: "8AC10462XH6416514", status: :completed}} =
               Payment.capture(authorization_id, capture_data)
    end

    test "successfully captures an authorization with headers", %{bypass: bypass} do
      authorization_id = "5UY53123AX394662R"

      Bypass.expect_once(
        bypass,
        "POST",
        "/v2/payments/authorizations/#{authorization_id}/capture",
        fn conn ->
          # Check that headers are sent
          assert Plug.Conn.get_req_header(conn, "paypal-request-id") == ["test-request-id"]
          assert Plug.Conn.get_req_header(conn, "prefer") == ["return=minimal"]

          response(conn, 201, %{
            "id" => "8AC10462XH6416514",
            "status" => "COMPLETED",
            "amount" => %{
              "currency_code" => "USD",
              "value" => "100.00"
            },
            "final_capture" => true,
            "create_time" => "2024-10-23T20:55:19Z",
            "update_time" => "2024-10-23T20:55:19Z",
            "links" => [
              %{
                "href" =>
                  "https://api-m.sandbox.paypal.com/v2/payments/captures/8AC10462XH6416514",
                "rel" => "self",
                "method" => "GET"
              }
            ]
          })
        end
      )

      assert {:ok, %Paypal.Payment.Captured{id: "8AC10462XH6416514", status: :completed}} =
               Payment.capture(authorization_id, %{}, [
                 {"PayPal-Request-Id", "test-request-id"},
                 {"Prefer", "return=minimal"}
               ])
    end

    test "handles API error when capturing", %{bypass: bypass} do
      authorization_id = "INVALID_AUTH"

      Bypass.expect_once(
        bypass,
        "POST",
        "/v2/payments/authorizations/#{authorization_id}/capture",
        fn conn ->
          response(conn, 404, %{
            "name" => "INVALID_REQUEST",
            "message" =>
              "Request is not well-formed, syntactically incorrect, or violates schema.",
            "debug_id" => "debug_id_here",
            "details" => [
              %{
                "field" => "authorization_id",
                "value" => authorization_id,
                "location" => "path",
                "issue" => "INVALID_AUTHORIZATION_ID",
                "description" => "The specified authorization ID is invalid."
              }
            ]
          })
        end
      )

      assert {:error, %Paypal.Common.Error{name: "INVALID_REQUEST"}} =
               Payment.capture(authorization_id)
    end
  end

  describe "show_capture/1" do
    test "successfully shows capture details", %{bypass: bypass} do
      capture_id = "8AC10462XH6416514"

      Bypass.expect_once(bypass, "GET", "/v2/payments/captures/#{capture_id}", fn conn ->
        response(conn, 200, %{
          "id" => capture_id,
          "status" => "COMPLETED",
          "amount" => %{
            "currency_code" => "USD",
            "value" => "100.00"
          },
          "final_capture" => true,
          "create_time" => "2024-10-23T20:55:19Z",
          "update_time" => "2024-10-23T20:55:19Z",
          "links" => [
            %{
              "href" => "https://api-m.sandbox.paypal.com/v2/payments/captures/#{capture_id}",
              "rel" => "self",
              "method" => "GET"
            }
          ]
        })
      end)

      assert {:ok, %Paypal.Payment.Captured{id: ^capture_id, status: :completed}} =
               Payment.show_capture(capture_id)
    end

    test "handles API error when showing capture", %{bypass: bypass} do
      capture_id = "INVALID_CAPTURE"

      Bypass.expect_once(bypass, "GET", "/v2/payments/captures/#{capture_id}", fn conn ->
        response(conn, 404, %{
          "name" => "INVALID_REQUEST",
          "message" => "Request is not well-formed, syntactically incorrect, or violates schema.",
          "debug_id" => "debug_id_here",
          "details" => [
            %{
              "field" => "capture_id",
              "value" => capture_id,
              "location" => "path",
              "issue" => "INVALID_CAPTURE_ID",
              "description" => "The specified capture ID is invalid."
            }
          ]
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "INVALID_REQUEST"}} =
               Payment.show_capture(capture_id)
    end
  end

  describe "show_refund/1" do
    test "successfully shows refund details", %{bypass: bypass} do
      refund_id = "1JU08902781691411"

      Bypass.expect_once(bypass, "GET", "/v2/payments/refunds/#{refund_id}", fn conn ->
        response(conn, 200, %{
          "id" => refund_id,
          "status" => "COMPLETED",
          "amount" => %{
            "value" => "10.99",
            "currency_code" => "USD"
          },
          "note" => "Defective product",
          "create_time" => "2018-09-11T23:24:19Z",
          "update_time" => "2018-09-11T23:24:19Z",
          "links" => [
            %{
              "rel" => "self",
              "method" => "GET",
              "href" => "https://api-m.paypal.com/v2/payments/refunds/#{refund_id}"
            }
          ]
        })
      end)

      assert {:ok, %Paypal.Payment.Refund{id: ^refund_id, status: :completed}} =
               Payment.show_refund(refund_id)
    end

    test "handles API error when showing refund", %{bypass: bypass} do
      refund_id = "INVALID_REFUND"

      Bypass.expect_once(bypass, "GET", "/v2/payments/refunds/#{refund_id}", fn conn ->
        response(conn, 404, %{
          "name" => "INVALID_REQUEST",
          "message" => "Request is not well-formed, syntactically incorrect, or violates schema.",
          "debug_id" => "debug_id_here",
          "details" => [
            %{
              "field" => "refund_id",
              "value" => refund_id,
              "location" => "path",
              "issue" => "INVALID_REFUND_ID",
              "description" => "The specified refund ID is invalid."
            }
          ]
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "INVALID_REQUEST"}} =
               Payment.show_refund(refund_id)
    end
  end
end
