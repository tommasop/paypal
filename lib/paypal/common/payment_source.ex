defmodule Paypal.Common.PaymentSource do
  @moduledoc """
  Payment source information for orders and payments.
  """
  use TypedEctoSchema

  @primary_key false

  typed_embedded_schema do
    # PayPal wallet
    embeds_one(:paypal, Paypal, primary_key: false) do
      @moduledoc "PayPal payment source"
      field(:email_address, :string)
      field(:account_id, :string)
      field(:account_status, :string)
      field(:name, :map)
      field(:given_name, :string)
      field(:surname, :string)
      field(:address, :map)
    end

    # Card payment
    embeds_one(:card, Card, primary_key: false) do
      @moduledoc "Card payment source"
      field(:last_digits, :string)
      field(:brand, :string)
      field(:type, :string)

      embeds_one(:authentication_result, AuthenticationResult, primary_key: false) do
        field(:liability_shift, :string)
        field(:three_d_secure, :map)
        field(:authentication_status, :string)
      end
    end

    # Bank payment (for some regions)
    embeds_one(:bank, Bank, primary_key: false) do
      @moduledoc "Bank payment source"
      field(:account_number, :string)
      field(:routing_number, :string)
      field(:account_type, :string)
      field(:country_code, :string)
    end
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end

  @doc false
  def changeset(struct, params) do
    struct
    |> Ecto.Changeset.cast(params, [])
    |> Ecto.Changeset.cast_embed(:paypal)
    |> Ecto.Changeset.cast_embed(:card)
    |> Ecto.Changeset.cast_embed(:bank)
  end
end
