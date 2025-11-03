defmodule Paypal.OrderValidationTest do
  use ExUnit.Case

  alias Paypal.Order

  describe "patch validation" do
    test "validates patch data structure" do
      order_id = "5UY53123AX394662R"

      # Invalid patch data - missing required fields
      invalid_patch_data = [
        %{
          op: "replace",
          # missing path
          value: %{
            currency_code: "EUR",
            value: "15.00"
          }
        }
      ]

      # Should fail validation before making HTTP request
      assert {:error, {:error, %Ecto.Changeset{}}} = Order.patch(order_id, invalid_patch_data)
    end
  end

  describe "tracker validation" do
    test "validates tracker data structure" do
      order_id = "5UY53123AX394662R"

      # Invalid tracker data - missing required fields
      invalid_tracker_data = %{
        # missing transaction_id
        tracking_number: "1Z999AA1234567890",
        carrier: "UPS"
      }

      # Should fail validation before making HTTP request
      assert {:error, %Ecto.Changeset{}} = Order.track(order_id, invalid_tracker_data)
    end
  end

  describe "callback validation" do
    test "validates callback data structure" do
      order_id = "5UY53123AX394662R"

      # Invalid callback data - missing required fields
      invalid_callback_data = %{
        # missing callback_url
        callback_timeout: "5"
      }

      # Should fail validation before making HTTP request
      assert {:error,
              %Ecto.Changeset{
                valid?: false,
                errors: [callback_url: {"can't be blank", [validation: :required]}]
              }} = Order.callback(order_id, invalid_callback_data)
    end
  end
end
