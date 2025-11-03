defmodule Paypal.Webhook.Info do
  @moduledoc """
  Schema for PayPal webhook information.

  This module defines the structure for webhook data returned by PayPal,
  including the webhook ID, URL, event types, and status.
  """
  use TypedEctoSchema

  alias Paypal.Common.Link

  @primary_key false

  @statuses [
    enabled: "ENABLED",
    disabled: "DISABLED",
    deleted: "DELETED"
  ]

  @typedoc """
  The information for a webhook:

  - `id` is the unique identifier for the webhook
  - `url` is the HTTPS URL where notifications are sent
  - `event_types` is the list of event types the webhook is subscribed to
  - `status` indicates if the webhook is enabled, disabled, or deleted
  - `create_time` is when the webhook was created
  - `update_time` is when the webhook was last updated
  - `links` are HATEOAS links for webhook operations
  """
  typed_embedded_schema do
    field(:id, :string, primary_key: true)
    field(:url, :string)
    field(:event_types, {:array, :string})
    field(:status, Ecto.Enum, values: @statuses, embed_as: :dumped)
    field(:create_time, :utc_datetime)
    field(:update_time, :utc_datetime)
    embeds_many(:links, Link)
  end

  @doc false
  def cast(params) do
    # Transform event_types from list of maps to list of strings
    params =
      case params do
        %{"event_types" => event_types} when is_list(event_types) ->
          transformed_event_types =
            Enum.map(event_types, fn
              %{"name" => name} -> name
              name when is_binary(name) -> name
            end)

          Map.put(params, "event_types", transformed_event_types)

        _ ->
          params
      end

    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
