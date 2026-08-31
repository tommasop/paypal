defmodule Paypal.VaultTest do
  use Paypal.Case

  alias Paypal.Auth.Worker, as: AuthWorker
  alias Paypal.Vault

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

    case Paypal.Auth.get_token() do
      {:ok, "ACCESSTOKEN"} -> :ok
      _ -> AuthWorker.refresh()
    end

    :ok
  end

  test "create_payment_token posts to /v1/vault/payment-tokens", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/v1/vault/payment-tokens", fn conn ->
      response(conn, 200, %{
        "id" => "token_123",
        "status" => "CREATED",
        "customer" => %{"id" => "cus_123"}
      })
    end)

    payment_source = %{"card" => %{"number" => "4111111111111111", "expiry" => "2030-12"}}

    assert {:ok, token} = Vault.create_payment_token(payment_source)
    assert token["id"] == "token_123"
    assert token["status"] == "CREATED"
  end

  test "delete_payment_token deletes by id", %{bypass: bypass} do
    Bypass.expect_once(bypass, "DELETE", "/v1/vault/payment-tokens/token_123", fn conn ->
      Plug.Conn.send_resp(conn, 204, "")
    end)

    assert :ok = Vault.delete_payment_token("token_123")
  end

  test "create_payment_token surfaces PayPal errors", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/v1/vault/payment-tokens", fn conn ->
      response(conn, 400, %{
        "name" => "INVALID_REQUEST",
        "message" => "bad request",
        "debug_id" => "dbg_1"
      })
    end)

    assert {:error, %Paypal.Common.Error{debug_id: "dbg_1"}} =
             Vault.create_payment_token(%{"card" => %{}})
  end
end
