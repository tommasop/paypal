defmodule Paypal.Order.Patch do
  @moduledoc """
  Represents a patch operation for updating an order.

  This module defines the structure for JSON Patch operations that can be applied
  to an order to modify its properties.
  """

  use TypedEctoSchema
  import Ecto.Changeset

  @primary_key false
  typed_embedded_schema do
    field(:op, Ecto.Enum, values: [:add, :remove, :replace, :move, :copy, :test])
    field(:path, :string)
    field(:value, :map)
    field(:from, :string)
  end

  @doc """
  Creates a changeset for validating patch operation data.
  """
  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:op, :path, :value, :from])
    |> validate_required([:op, :path])
    |> validate_inclusion(:op, [:add, :remove, :replace, :move, :copy, :test])
    |> validate_path_format()
  end

  defp validate_path_format(changeset) do
    path = get_field(changeset, :path)
    op = get_field(changeset, :op)

    if path && op in [:add, :remove, :replace, :test] do
      # Basic path validation - should start with /
      if not String.starts_with?(path, "/") do
        add_error(changeset, :path, "must start with /")
      else
        changeset
      end
    else
      changeset
    end
  end
end
