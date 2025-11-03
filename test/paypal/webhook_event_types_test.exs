defmodule Paypal.Webhook.EventTypesTest do
  use ExUnit.Case, async: true
  alias Paypal.Webhook.EventTypes

  describe "all/0" do
    test "returns all available event types" do
      event_types = EventTypes.all()
      assert is_list(event_types)
      assert length(event_types) > 10

      # Check some specific event types are included
      assert "PAYMENT.CAPTURE.COMPLETED" in event_types
      assert "CHECKOUT.ORDER.APPROVED" in event_types
      assert "PAYMENT.REFUND.COMPLETED" in event_types
    end
  end

  describe "payment_events/0" do
    test "returns only payment-related event types" do
      payment_events = EventTypes.payment_events()

      assert Enum.all?(payment_events, &String.starts_with?(&1, "PAYMENT."))

      # Check specific payment events
      assert "PAYMENT.CAPTURE.COMPLETED" in payment_events
      assert "PAYMENT.AUTHORIZATION.CREATED" in payment_events
      assert "PAYMENT.REFUND.COMPLETED" in payment_events
    end
  end

  describe "order_events/0" do
    test "returns only order-related event types" do
      order_events = EventTypes.order_events()

      assert Enum.all?(order_events, &String.starts_with?(&1, "CHECKOUT.ORDER."))

      # Check specific order events
      assert "CHECKOUT.ORDER.APPROVED" in order_events
      assert "CHECKOUT.ORDER.COMPLETED" in order_events
    end
  end

  describe "dispute_events/0" do
    test "returns only dispute-related event types" do
      dispute_events = EventTypes.dispute_events()

      assert Enum.all?(dispute_events, &String.starts_with?(&1, "CUSTOMER.DISPUTE."))

      # Check specific dispute events
      assert "CUSTOMER.DISPUTE.CREATED" in dispute_events
      assert "CUSTOMER.DISPUTE.RESOLVED" in dispute_events
    end
  end

  describe "subscription_events/0" do
    test "returns only subscription-related event types" do
      subscription_events = EventTypes.subscription_events()

      assert Enum.all?(subscription_events, &String.starts_with?(&1, "BILLING.SUBSCRIPTION."))

      # Check specific subscription events
      assert "BILLING.SUBSCRIPTION.CREATED" in subscription_events
      assert "BILLING.SUBSCRIPTION.ACTIVATED" in subscription_events
    end
  end

  describe "payout_events/0" do
    test "returns only payout-related event types" do
      payout_events = EventTypes.payout_events()

      assert Enum.all?(payout_events, &String.starts_with?(&1, "PAYMENT.PAYOUTS"))

      # Check specific payout events
      assert "PAYMENT.PAYOUTSBATCH.SUCCESS" in payout_events
      assert "PAYMENT.PAYOUTS-ITEM.SUCCEEDED" in payout_events
    end
  end
end
