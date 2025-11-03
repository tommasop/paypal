defmodule Paypal.Order.Confirm do
  @moduledoc """
  Represents the response from confirming a payment source for an order.
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Paypal.Common.Link

  @primary_key false
  typed_embedded_schema do
    field(:id, :string)

    field(:status, Ecto.Enum,
      values: [:created, :saved, :approved, :voided, :completed, :payer_action_required]
    )

    field(:payment_source, :map)
    embeds_many(:links, Link)
  end

  @doc """
  Creates a Confirm struct from API response data.
  """
  @spec cast(map()) :: t()
  def cast(data) do
    data =
      Map.update(data, "status", nil, fn status ->
        case status do
          "CREATED" -> :created
          "SAVED" -> :saved
          "APPROVED" -> :approved
          "VOIDED" -> :voided
          "COMPLETED" -> :completed
          "PAYER_ACTION_REQUIRED" -> :payer_action_required
          _ -> status
        end
      end)

    Ecto.embedded_load(__MODULE__, data, :json)
  end
end
