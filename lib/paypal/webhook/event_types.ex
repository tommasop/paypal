defmodule Paypal.Webhook.EventTypes do
  @moduledoc """
  PayPal webhook event types constants.

  This module contains all the standard webhook event types that PayPal can send.
  Use these constants when creating or filtering webhooks.
  """

  @doc """
  All available webhook event types.
  """
  def all do
    [
      # Checkout/Order events
      "CHECKOUT.ORDER.APPROVED",
      "CHECKOUT.ORDER.COMPLETED",
      "CHECKOUT.ORDER.PROCESSED",

      # Payment Authorization events
      "PAYMENT.AUTHORIZATION.CREATED",
      "PAYMENT.AUTHORIZATION.VOIDED",

      # Payment Capture events
      "PAYMENT.CAPTURE.COMPLETED",
      "PAYMENT.CAPTURE.DENIED",
      "PAYMENT.CAPTURE.PENDING",
      "PAYMENT.CAPTURE.REFUNDED",
      "PAYMENT.CAPTURE.REVERSED",

      # Payment Refund events
      "PAYMENT.REFUND.COMPLETED",
      "PAYMENT.REFUND.DENIED",

      # Customer Dispute events
      "CUSTOMER.DISPUTE.CREATED",
      "CUSTOMER.DISPUTE.RESOLVED",

      # Billing/Subscription events
      "BILLING.SUBSCRIPTION.CREATED",
      "BILLING.SUBSCRIPTION.ACTIVATED",
      "BILLING.SUBSCRIPTION.UPDATED",
      "BILLING.SUBSCRIPTION.CANCELLED",
      "BILLING.SUBSCRIPTION.SUSPENDED",
      "BILLING.SUBSCRIPTION.RE-ACTIVATED",
      "BILLING.SUBSCRIPTION.EXPIRED",

      # Invoice events
      "INVOICING.INVOICE.CREATED",
      "INVOICING.INVOICE.SENT",
      "INVOICING.INVOICE.PAID",
      "INVOICING.INVOICE.CANCELLED",
      "INVOICING.INVOICE.REFUNDED",

      # Payout events
      "PAYMENT.PAYOUTSBATCH.DENIED",
      "PAYMENT.PAYOUTSBATCH.PROCESSING",
      "PAYMENT.PAYOUTSBATCH.SUCCESS",
      "PAYMENT.PAYOUTS-ITEM.BLOCKED",
      "PAYMENT.PAYOUTS-ITEM.CANCELLED",
      "PAYMENT.PAYOUTS-ITEM.DENIED",
      "PAYMENT.PAYOUTS-ITEM.FAILED",
      "PAYMENT.PAYOUTS-ITEM.HELD",
      "PAYMENT.PAYOUTS-ITEM.PROCESSING",
      "PAYMENT.PAYOUTS-ITEM.REFUNDED",
      "PAYMENT.PAYOUTS-ITEM.RETURNED",
      "PAYMENT.PAYOUTS-ITEM.SUCCEEDED",
      "PAYMENT.PAYOUTS-ITEM.UNCLAIMED"
    ]
  end

  @doc """
  Payment-related event types.
  """
  def payment_events do
    [
      "PAYMENT.AUTHORIZATION.CREATED",
      "PAYMENT.AUTHORIZATION.VOIDED",
      "PAYMENT.CAPTURE.COMPLETED",
      "PAYMENT.CAPTURE.DENIED",
      "PAYMENT.CAPTURE.PENDING",
      "PAYMENT.CAPTURE.REFUNDED",
      "PAYMENT.CAPTURE.REVERSED",
      "PAYMENT.REFUND.COMPLETED",
      "PAYMENT.REFUND.DENIED"
    ]
  end

  @doc """
  Order-related event types.
  """
  def order_events do
    [
      "CHECKOUT.ORDER.APPROVED",
      "CHECKOUT.ORDER.COMPLETED",
      "CHECKOUT.ORDER.PROCESSED"
    ]
  end

  @doc """
  Dispute-related event types.
  """
  def dispute_events do
    [
      "CUSTOMER.DISPUTE.CREATED",
      "CUSTOMER.DISPUTE.RESOLVED"
    ]
  end

  @doc """
  Subscription-related event types.
  """
  def subscription_events do
    [
      "BILLING.SUBSCRIPTION.CREATED",
      "BILLING.SUBSCRIPTION.ACTIVATED",
      "BILLING.SUBSCRIPTION.UPDATED",
      "BILLING.SUBSCRIPTION.CANCELLED",
      "BILLING.SUBSCRIPTION.SUSPENDED",
      "BILLING.SUBSCRIPTION.RE-ACTIVATED",
      "BILLING.SUBSCRIPTION.EXPIRED"
    ]
  end

  @doc """
  Payout-related event types.
  """
  def payout_events do
    [
      "PAYMENT.PAYOUTSBATCH.DENIED",
      "PAYMENT.PAYOUTSBATCH.PROCESSING",
      "PAYMENT.PAYOUTSBATCH.SUCCESS",
      "PAYMENT.PAYOUTS-ITEM.BLOCKED",
      "PAYMENT.PAYOUTS-ITEM.CANCELLED",
      "PAYMENT.PAYOUTS-ITEM.DENIED",
      "PAYMENT.PAYOUTS-ITEM.FAILED",
      "PAYMENT.PAYOUTS-ITEM.HELD",
      "PAYMENT.PAYOUTS-ITEM.PROCESSING",
      "PAYMENT.PAYOUTS-ITEM.REFUNDED",
      "PAYMENT.PAYOUTS-ITEM.RETURNED",
      "PAYMENT.PAYOUTS-ITEM.SUCCEEDED",
      "PAYMENT.PAYOUTS-ITEM.UNCLAIMED"
    ]
  end
end
