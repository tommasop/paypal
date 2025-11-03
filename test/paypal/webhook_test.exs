defmodule Paypal.WebhookTest do
  use Paypal.Case
  alias Paypal.Auth.Worker, as: AuthWorker
  alias Paypal.Webhook

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

  describe "create/1" do
    test "successfully creates a webhook with valid parameters", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v1/notifications/webhooks", fn conn ->
        response(conn, 201, %{
          "id" => "WEBHOOK-123",
          "url" => "https://example.com/webhook",
          "event_types" => ["PAYMENT.CAPTURE.COMPLETED"],
          "status" => "ENABLED",
          "create_time" => "2024-01-01T00:00:00Z",
          "update_time" => "2024-01-01T00:00:00Z",
          "links" => [
            %{
              "href" => "https://api.sandbox.paypal.com/v1/notifications/webhooks/WEBHOOK-123",
              "rel" => "self",
              "method" => "GET"
            }
          ]
        })
      end)

      params = %{
        url: "https://example.com/webhook",
        event_types: ["PAYMENT.CAPTURE.COMPLETED"]
      }

      assert {:ok, webhook} = Webhook.create(params)
      assert webhook.id == "WEBHOOK-123"
      assert webhook.url == "https://example.com/webhook"
      assert webhook.event_types == ["PAYMENT.CAPTURE.COMPLETED"]
      assert webhook.status == :enabled
    end

    test "validates required parameters", %{bypass: bypass} do
      # Missing url
      params = %{event_types: ["PAYMENT.CAPTURE.COMPLETED"]}
      assert {:error, changeset} = Webhook.create(params)
      assert %{url: ["can't be blank"]} = errors_on(changeset)

      # Missing event_types
      params = %{url: "https://example.com/webhook"}
      assert {:error, changeset} = Webhook.create(params)
      assert %{event_types: ["can't be blank"]} = errors_on(changeset)

      # Empty event_types
      params = %{url: "https://example.com/webhook", event_types: []}
      assert {:error, changeset} = Webhook.create(params)
      assert %{event_types: ["at least one event type is required"]} = errors_on(changeset)
    end

    test "validates HTTPS URL", %{bypass: bypass} do
      params = %{
        # HTTP instead of HTTPS
        url: "http://example.com/webhook",
        event_types: ["PAYMENT.CAPTURE.COMPLETED"]
      }

      assert {:error, changeset} = Webhook.create(params)
      assert %{url: ["webhook URL must use HTTPS"]} = errors_on(changeset)
    end

    test "handles API errors", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v1/notifications/webhooks", fn conn ->
        response(conn, 400, %{
          "name" => "INVALID_REQUEST",
          "message" => "Request is not well-formed",
          "details" => [
            %{
              "field" => "url",
              "issue" => "INVALID_URL"
            }
          ]
        })
      end)

      params = %{
        url: "https://example.com/webhook",
        event_types: ["PAYMENT.CAPTURE.COMPLETED"]
      }

      assert {:error, error} = Webhook.create(params)
      assert error.name == "INVALID_REQUEST"
    end
  end

  describe "list/0" do
    test "successfully lists webhooks", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v1/notifications/webhooks", fn conn ->
        response(conn, 200, %{
          "webhooks" => [
            %{
              "id" => "WEBHOOK-123",
              "url" => "https://example.com/webhook1",
              "event_types" => ["PAYMENT.CAPTURE.COMPLETED"],
              "status" => "ENABLED"
            },
            %{
              "id" => "WEBHOOK-456",
              "url" => "https://example.com/webhook2",
              "event_types" => ["CHECKOUT.ORDER.APPROVED"],
              "status" => "DISABLED"
            }
          ]
        })
      end)

      assert {:ok, webhooks} = Webhook.list()
      assert length(webhooks) == 2

      [webhook1, webhook2] = webhooks
      assert webhook1.id == "WEBHOOK-123"
      assert webhook1.status == :enabled
      assert webhook2.id == "WEBHOOK-456"
      assert webhook2.status == :disabled
    end

    test "handles API errors", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v1/notifications/webhooks", fn conn ->
        response(conn, 500, %{
          "name" => "INTERNAL_SERVER_ERROR",
          "message" => "Internal server error"
        })
      end)

      assert {:error, error} = Webhook.list()
      assert error.name == "INTERNAL_SERVER_ERROR"
    end
  end

  describe "show/1" do
    test "successfully shows webhook details", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v1/notifications/webhooks/WEBHOOK-123", fn conn ->
        response(conn, 200, %{
          "id" => "WEBHOOK-123",
          "url" => "https://example.com/webhook",
          "event_types" => ["PAYMENT.CAPTURE.COMPLETED"],
          "status" => "ENABLED",
          "create_time" => "2024-01-01T00:00:00Z",
          "update_time" => "2024-01-01T00:00:00Z"
        })
      end)

      assert {:ok, webhook} = Webhook.show("WEBHOOK-123")
      assert webhook.id == "WEBHOOK-123"
      assert webhook.url == "https://example.com/webhook"
      assert webhook.status == :enabled
    end

    test "handles not found error", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v1/notifications/webhooks/WEBHOOK-123", fn conn ->
        response(conn, 404, %{
          "name" => "RESOURCE_NOT_FOUND",
          "message" => "Webhook not found"
        })
      end)

      assert {:error, error} = Webhook.show("WEBHOOK-123")
      assert error.name == "RESOURCE_NOT_FOUND"
    end
  end

  describe "update/2" do
    test "successfully updates webhook", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PATCH", "/v1/notifications/webhooks/WEBHOOK-123", fn conn ->
        response(conn, 200, %{
          "id" => "WEBHOOK-123",
          "url" => "https://example.com/new-webhook",
          "event_types" => ["PAYMENT.CAPTURE.COMPLETED", "CHECKOUT.ORDER.APPROVED"],
          "status" => "ENABLED"
        })
      end)

      params = %{
        url: "https://example.com/new-webhook",
        event_types: ["PAYMENT.CAPTURE.COMPLETED", "CHECKOUT.ORDER.APPROVED"]
      }

      assert {:ok, webhook} = Webhook.update("WEBHOOK-123", params)
      assert webhook.url == "https://example.com/new-webhook"
      assert length(webhook.event_types) == 2
    end

    test "handles invalid update parameters", %{bypass: bypass} do
      # No valid fields to update
      assert {:error, "No valid fields to update"} =
               Webhook.update("WEBHOOK-123", %{invalid_field: "value"})
    end
  end

  describe "delete/1" do
    test "successfully deletes webhook", %{bypass: bypass} do
      Bypass.expect_once(bypass, "DELETE", "/v1/notifications/webhooks/WEBHOOK-123", fn conn ->
        response(conn, 204, nil)
      end)

      assert :ok = Webhook.delete("WEBHOOK-123")
    end

    test "handles delete errors", %{bypass: bypass} do
      Bypass.expect_once(bypass, "DELETE", "/v1/notifications/webhooks/WEBHOOK-123", fn conn ->
        response(conn, 404, %{
          "name" => "RESOURCE_NOT_FOUND",
          "message" => "Webhook not found"
        })
      end)

      assert {:error, error} = Webhook.delete("WEBHOOK-123")
      assert error.name == "RESOURCE_NOT_FOUND"
    end
  end

  describe "verify_signature/2" do
    test "successfully verifies valid signature", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v1/notifications/verify-webhook-signature", fn conn ->
        response(conn, 200, %{"verification_status" => "SUCCESS"})
      end)

      webhook_body = %{"id" => "WH-123", "event_type" => "PAYMENT.CAPTURE.COMPLETED"}

      headers = %{
        "paypal-auth-algo" => "SHA256withRSA",
        "paypal-cert-url" => "https://api.paypal.com/v1/notifications/certs/CERT-123",
        "paypal-transmission-id" => "transmission-123",
        "paypal-transmission-sig" => "signature-123",
        "paypal-transmission-time" => "2024-01-01T00:00:00Z",
        "paypal-webhook-id" => "WEBHOOK-123"
      }

      assert {:ok, :verified} = Webhook.verify_signature(webhook_body, headers)
    end

    test "rejects invalid signature", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v1/notifications/verify-webhook-signature", fn conn ->
        response(conn, 200, %{"verification_status" => "FAILURE"})
      end)

      webhook_body = %{"id" => "WH-123", "event_type" => "PAYMENT.CAPTURE.COMPLETED"}

      headers = %{
        "paypal-auth-algo" => "SHA256withRSA",
        "paypal-cert-url" => "https://api.paypal.com/v1/notifications/certs/CERT-123",
        "paypal-transmission-id" => "transmission-123",
        "paypal-transmission-sig" => "invalid-signature",
        "paypal-transmission-time" => "2024-01-01T00:00:00Z",
        "paypal-webhook-id" => "WEBHOOK-123"
      }

      assert {:error, :invalid_signature} = Webhook.verify_signature(webhook_body, headers)
    end

    test "validates required signature headers", %{bypass: bypass} do
      webhook_body = %{"id" => "WH-123", "event_type" => "PAYMENT.CAPTURE.COMPLETED"}
      # Missing required headers
      headers = %{}

      assert {:error, changeset} = Webhook.verify_signature(webhook_body, headers)
      assert %{auth_algo: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "parse_event/1" do
    test "successfully parses webhook event" do
      event_data = %{
        "id" => "WH-123",
        "create_time" => "2024-01-01T00:00:00Z",
        "resource_type" => "capture",
        "event_type" => "PAYMENT.CAPTURE.COMPLETED",
        "summary" => "Payment captured",
        "resource" => %{"id" => "CAPTURE-123", "amount" => %{"value" => "10.00"}},
        "links" => [
          %{"href" => "https://api.paypal.com/v2/payments/captures/CAPTURE-123", "rel" => "self"}
        ]
      }

      assert {:ok, event} = Webhook.parse_event(event_data)
      assert event.id == "WH-123"
      assert event.event_type == "PAYMENT.CAPTURE.COMPLETED"
      assert event.resource_type == "capture"
      assert Webhook.Event.payment_event?(event)
      refute Webhook.Event.order_event?(event)
    end

    test "handles invalid event data" do
      invalid_data = %{"invalid" => "data"}
      assert {:error, _} = Webhook.parse_event(invalid_data)
    end
  end
end
