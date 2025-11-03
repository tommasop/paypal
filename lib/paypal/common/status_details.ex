defmodule Paypal.Common.StatusDetails do
  @moduledoc """
  Status details for payments, captures, and refunds.
  """
  use TypedEctoSchema

  @reasons [
    buyer_complaint: "BUYER_COMPLAINT",
    chargeback: "CHARGEBACK",
    echeck: "ECHECK",
    international_withdrawal: "INTERNATIONAL_WITHDRAWAL",
    other: "OTHER",
    pending_review: "PENDING_REVIEW",
    receiving_preference_mandates_manual_action: "RECEIVING_PREFERENCE_MANDATES_MANUAL_ACTION",
    refunded: "REFUNDED",
    transaction_approved_aft: "TRANSACTION_APPROVED_AFT",
    unilateral: "UNILATERAL",
    verification_required: "VERIFICATION_REQUIRED"
  ]

  @primary_key false

  typed_embedded_schema do
    field(:reason, Ecto.Enum, values: @reasons)
  end
end
