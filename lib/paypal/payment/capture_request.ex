defmodule Paypal.Payment.CaptureRequest do
  @moduledoc """
  Request object for capturing an authorized payment.

  ## Fields

    - `invoice_id` - The API caller-provided external invoice number for this order.
    - `note_to_payer` - An informational note about this settlement.
    - `final_capture` - Indicates whether you can make additional captures against the authorized payment.
    - `payment_instruction` - Any additional payment instructions to be consider during payment processing.
    - `soft_descriptor` - The payment descriptor on the payer's account statement.
    - `amount` - The amount to capture. If not specified, the full authorized amount is captured.
  """
  use TypedEctoSchema

  import Ecto.Changeset
  import Paypal.EctoHelpers

  alias Paypal.Common.CurrencyValue

  @derive Jason.Encoder
  @primary_key false
  typed_embedded_schema do
    field(:invoice_id, :string)
    field(:note_to_payer, :string)
    field(:final_capture, :boolean)
    # TODO
    field(:payment_instruction, :map)
    field(:soft_descriptor, :string)
    embeds_one(:amount, CurrencyValue)
  end

  @fields ~w[
    invoice_id
    note_to_payer
    final_capture
    payment_instruction
    soft_descriptor
  ]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @fields)
    |> cast_embed(:amount)
    |> case do
      %Ecto.Changeset{valid?: true} = changeset ->
        {:ok,
         changeset
         |> apply_changes()
         |> Ecto.embedded_dump(:json)
         |> clean_data()}

      %Ecto.Changeset{} = changeset ->
        {:error, traverse_errors(changeset)}
    end
  end
end
