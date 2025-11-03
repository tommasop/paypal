defmodule Paypal.Order.Payer do
  @moduledoc """
  Payer get all the information about who's paying the order.
  """
  use TypedEctoSchema

  alias Paypal.Common.Name
  alias Paypal.Common.Address

  @primary_key false

  @typedoc """
  The information for the payer:

  - `payer_id` is the ID in Paypal for the payer.
  - `name` is the payer's name information.
  - `email_address` is the email address provided to Paypal for the payment.
  - `address` is the payer's address information.
  """
  typed_embedded_schema do
    field(:payer_id, :string, primary_key: true)
    embeds_one(:name, Name)
    field(:email_address, :string)
    embeds_one(:address, Address)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
