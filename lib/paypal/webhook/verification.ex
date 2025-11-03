defmodule Paypal.Webhook.Verification do
  @moduledoc """
  Schema for PayPal webhook signature verification.

  This module handles the verification of webhook signatures to ensure
  that webhook payloads are authentic and come from PayPal.
  """
  use TypedEctoSchema

  @primary_key false

  @verification_statuses [
    success: "SUCCESS",
    failure: "FAILURE"
  ]

  @typedoc """
  The information for webhook signature verification:

  - `verification_status` indicates if the signature verification succeeded
  """
  typed_embedded_schema do
    field(:verification_status, Ecto.Enum, values: @verification_statuses, embed_as: :dumped)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end

  @doc """
  Request structure for signature verification.
  """
  defmodule Request do
    @moduledoc """
    Schema for webhook signature verification requests.
    """
    use TypedEctoSchema

    @primary_key false

    typed_embedded_schema do
      field(:auth_algo, :string)
      field(:cert_url, :string)
      field(:transmission_id, :string)
      field(:transmission_sig, :string)
      field(:transmission_time, :string)
      field(:webhook_id, :string)
      field(:webhook_event, :map)
    end

    @doc false
    def changeset(struct, params) do
      struct
      |> Ecto.Changeset.cast(params, [
        :auth_algo,
        :cert_url,
        :transmission_id,
        :transmission_sig,
        :transmission_time,
        :webhook_id,
        :webhook_event
      ])
      |> Ecto.Changeset.validate_required([
        :auth_algo,
        :cert_url,
        :transmission_id,
        :transmission_sig,
        :transmission_time,
        :webhook_id,
        :webhook_event
      ])
    end
  end
end
