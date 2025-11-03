defmodule Paypal.PaymentValidationTest do
  use ExUnit.Case

  alias Paypal.Payment.CaptureRequest
  alias Paypal.Payment.ReauthorizeRequest

  describe "reauthorize request validation" do
    test "validates reauthorize data structure with amount" do
      valid_data = %{
        amount: %{
          currency_code: "USD",
          value: "100.00"
        }
      }

      assert {:ok, data} = ReauthorizeRequest.changeset(valid_data)
      assert data[:amount][:currency_code] == "USD"
      assert data[:amount][:value] == Decimal.new("100.00")
    end

    test "validates reauthorize data structure with empty body" do
      empty_data = %{}

      assert {:ok, data} = ReauthorizeRequest.changeset(empty_data)
      assert data == %{}
    end

    test "validates reauthorize data structure with invalid amount" do
      invalid_data = %{
        amount: %{
          currency_code: "INVALID",
          value: "not_a_number"
        }
      }

      assert {:error, _errors} = ReauthorizeRequest.changeset(invalid_data)
      # The changeset should catch invalid currency or value format
      # but since we're using embedded schema, it might pass basic validation
      # The actual validation happens at the CurrencyValue level
    end
  end

  describe "capture request validation" do
    test "validates capture data structure with full parameters" do
      valid_data = %{
        invoice_id: "OrderInvoice-123",
        note_to_payer: "Thank you for your payment",
        final_capture: true,
        soft_descriptor: "PAYPAL *TEST STORE",
        amount: %{
          currency_code: "USD",
          value: "100.00"
        }
      }

      assert {:ok, data} = CaptureRequest.changeset(valid_data)
      assert data[:invoice_id] == "OrderInvoice-123"
      assert data[:note_to_payer] == "Thank you for your payment"
      assert data[:final_capture] == true
      assert data[:soft_descriptor] == "PAYPAL *TEST STORE"
      assert data[:amount][:currency_code] == "USD"
      assert data[:amount][:value] == Decimal.new("100.00")
    end

    test "validates capture data structure with empty body" do
      empty_data = %{}

      assert {:ok, data} = CaptureRequest.changeset(empty_data)
      assert data == %{}
    end

    test "validates capture data structure with minimal parameters" do
      minimal_data = %{
        final_capture: false
      }

      assert {:ok, data} = CaptureRequest.changeset(minimal_data)
      assert data[:final_capture] == false
    end
  end
end
