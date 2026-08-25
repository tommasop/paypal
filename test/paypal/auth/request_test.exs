defmodule Paypal.Auth.RequestTest do
  use Paypal.Case

  alias Paypal.Auth.Request

  test "returns token body on success", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/v1/oauth2/token", fn conn ->
      response(conn, 200, %{
        "access_token" => "ACCESSTOKEN",
        "app_id" => "APP-ID",
        "expires_in" => 32_400,
        "nonce" => "NONCE",
        "scope" => "scope",
        "token_type" => "Bearer"
      })
    end)

    assert {:ok, body} = Request.auth()
    assert body["access_token"] == "ACCESSTOKEN"
  end

  test "returns error with status and body on non-2xx response", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/v1/oauth2/token", fn conn ->
      response(conn, 401, %{
        "error" => "invalid_client",
        "error_description" => "Client Authentication failed"
      })
    end)

    assert {:error, %{status: 401, body: %{"error" => "invalid_client"}}} = Request.auth()
  end
end
