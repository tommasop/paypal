defmodule Paypal.Payment.ReauthorizeRequest do
  @moduledoc """
  Request object for reauthorizing an authorized payment.

  ## Fields

    - `amount` - The amount to reauthorize for an authorized payment.
  """
  use TypedEctoSchema

  import Ecto.Changeset
  import Paypal.EctoHelpers

  alias Paypal.Common.CurrencyValue

  @derive Jason.Encoder
  @primary_key false
  typed_embedded_schema do
    embeds_one(:amount, CurrencyValue)
  end

  @fields []

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
