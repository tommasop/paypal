defmodule Paypal.Order.Callback do
  @moduledoc """
  Represents the response from updating an order with callback information.
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

    embeds_many(:links, Link)
  end

  @doc """
  Creates a Callback struct from API response data.
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
