defmodule AshTypescript.Codegen do
  def generate_ash_type_aliases(resources, actions) do
    resource_types =
      Enum.reduce(resources, MapSet.new(), fn resource, types ->
        types =
          resource
          |> Ash.Resource.Info.public_attributes()
          |> Enum.reduce(types, fn attr, types -> MapSet.put(types, attr.type) end)

        types =
          resource
          |> Ash.Resource.Info.public_calculations()
          |> Enum.reduce(types, fn calc, types -> MapSet.put(types, calc.type) end)

        resource
        |> Ash.Resource.Info.public_aggregates()
        |> Enum.reduce(types, fn agg, types ->
          type =
            case agg.kind do
              :sum ->
                resource
                |> lookup_aggregate_type(agg.relationship_path, agg.field)

              :first ->
                resource
                |> lookup_aggregate_type(agg.relationship_path, agg.field)

              _ ->
                agg.kind
            end

          if Ash.Type.ash_type?(type) do
            MapSet.put(types, type)
          else
            types
          end
        end)
      end)

    types =
      Enum.reduce(actions, resource_types, fn action, types ->
        action.arguments
        |> Enum.reduce(types, fn argument, types ->
          if Ash.Type.ash_type?(argument.type) do
            MapSet.put(types, argument.type)
          else
            types
          end
        end)

        if action.type == :action do
          if Ash.Type.ash_type?(action.returns) do
            case action.returns do
              {:array, type} -> MapSet.put(types, type)
              _ -> MapSet.put(types, action.returns)
            end
          else
            types
          end
        else
          types
        end
      end)

    Enum.map(types, fn type ->
      case type do
        {:array, type} -> generate_ash_type_alias(type)
        type -> generate_ash_type_alias(type)
      end
    end)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  defp generate_ash_type_alias(Ash.Type.Struct), do: ""
  defp generate_ash_type_alias(Ash.Type.Atom), do: ""
  defp generate_ash_type_alias(Ash.Type.Boolean), do: ""
  defp generate_ash_type_alias(Ash.Type.Integer), do: ""
  defp generate_ash_type_alias(Ash.Type.Map), do: ""
  defp generate_ash_type_alias(Ash.Type.String), do: ""
  defp generate_ash_type_alias(Ash.Type.UUID), do: "type UUID = string;"
  defp generate_ash_type_alias(Ash.Type.UUIDv7), do: "type UUIDv7 = string;"
  defp generate_ash_type_alias(Ash.Type.Decimal), do: "type Decimal = string;"
  defp generate_ash_type_alias(Ash.Type.Date), do: "type AshDate = string;"
  defp generate_ash_type_alias(Ash.Type.Time), do: "type Time = string;"
  defp generate_ash_type_alias(Ash.Type.TimeUsec), do: "type TimeUsec = string;"
  defp generate_ash_type_alias(Ash.Type.UtcDatetime), do: "type UtcDateTime = string;"
  defp generate_ash_type_alias(Ash.Type.UtcDatetimeUsec), do: "type UtcDateTimeUsec = string;"
  defp generate_ash_type_alias(Ash.Type.DateTime), do: "type DateTime = string;"
  defp generate_ash_type_alias(Ash.Type.NaiveDatetime), do: "type NaiveDateTime = string;"
  defp generate_ash_type_alias(Ash.Type.Duration), do: "type Duration = string;"
  defp generate_ash_type_alias(Ash.Type.DurationName), do: "type DurationName = string;"
  defp generate_ash_type_alias(Ash.Type.Binary), do: "type Binary = string;"
  defp generate_ash_type_alias(Ash.Type.UrlEncodedBinary), do: "type UrlEncodedBinary = string;"
  defp generate_ash_type_alias(Ash.Type.File), do: "type File = any;"
  defp generate_ash_type_alias(Ash.Type.Function), do: "type Function = any;"
  defp generate_ash_type_alias(Ash.Type.Module), do: "type ModuleName = string;"
  defp generate_ash_type_alias(AshDoubleEntry.ULID), do: "type ULID = string;"

  defp generate_ash_type_alias(AshMoney.Types.Money),
    do: "type Money = { amount: string; currency: string };"

  defp generate_ash_type_alias(type) do
    if Ash.Type.NewType.new_type?(type) or Spark.implements_behaviour?(type, Ash.Type.Enum) do
      ""
    else
      raise "Unknown type: #{type}"
    end
  end

  def generate_all_schemas_for_resources(resources, allowed_resources) do
    resources
    |> Enum.map(&generate_all_schemas_for_resource(&1, allowed_resources))
    |> Enum.join("\n\n")
  end

  def generate_all_schemas_for_resource(resource, allowed_resources) do
    resource_name = resource |> Module.split() |> List.last()

    resource_schema = generate_resource_schema(resource, allowed_resources)

    """
    // #{resource_name} Schema
    #{resource_schema}
    """
  end


  def generate_resource_schema(resource, allowed_resources) do
    resource_name = resource |> Module.split() |> List.last()

    # Get all fields (attributes, calculations, aggregates)
    attributes = Ash.Resource.Info.public_attributes(resource)
    calculations = Ash.Resource.Info.public_calculations(resource)
    aggregates = Ash.Resource.Info.public_aggregates(resource)

    fields =
      Enum.concat([attributes, calculations, aggregates])
      |> Enum.map(fn
        %Ash.Resource.Attribute{} = attr ->
          if attr.allow_nil? do
            "  #{attr.name}?: #{get_ts_type(attr)} | null;"
          else
            "  #{attr.name}: #{get_ts_type(attr)};"
          end

        %Ash.Resource.Calculation{} = calc ->
          if calc.allow_nil? do
            "  #{calc.name}?: #{get_ts_type(calc)} | null;"
          else
            "  #{calc.name}: #{get_ts_type(calc)};"
          end

        %Ash.Resource.Aggregate{} = agg ->
          type =
            case agg.kind do
              :sum ->
                resource
                |> lookup_aggregate_type(agg.relationship_path, agg.field)
                |> get_ts_type()

              :first ->
                resource
                |> lookup_aggregate_type(agg.relationship_path, agg.field)
                |> get_ts_type()

              _ ->
                get_ts_type(agg.kind)
            end

          if agg.include_nil? do
            "  #{agg.name}?: #{type} | null;"
          else
            "  #{agg.name}: #{type};"
          end
      end)

    # Get relationships
    relationships =
      resource
      |> Ash.Resource.Info.public_relationships()
      |> Enum.filter(fn rel ->
        # Only include relationships to allowed resources
        Enum.member?(allowed_resources, rel.destination)
      end)
      |> Enum.map(fn rel ->
        related_resource_name = rel.destination |> Module.split() |> List.last()

        case rel.type do
          :belongs_to ->
            if rel.allow_nil? do
              "  #{rel.name}?: #{related_resource_name} | null;"
            else
              "  #{rel.name}: #{related_resource_name};"
            end

          :has_one ->
            if rel.allow_nil? do
              "  #{rel.name}?: #{related_resource_name} | null;"
            else
              "  #{rel.name}: #{related_resource_name};"
            end

          :has_many ->
            "  #{rel.name}: #{related_resource_name}[];"

          :many_to_many ->
            "  #{rel.name}: #{related_resource_name}[];"
        end
      end)

    all_fields = fields ++ relationships

    """
    export type #{resource_name} = {
    #{Enum.join(all_fields, "\n")}
    };
    """
  end

  def get_ts_type(type_and_constraints, select_and_loads \\ nil)
  def get_ts_type(:count, _), do: "number"
  def get_ts_type(:sum, _), do: "number"
  def get_ts_type(:integer, _), do: "number"
  def get_ts_type(%{type: nil}, _), do: "null"
  def get_ts_type(%{type: :sum}, _), do: "number"
  def get_ts_type(%{type: :count}, _), do: "number"
  def get_ts_type(%{type: :map}, _), do: "Record<string, any>"

  def get_ts_type(%{type: Ash.Type.Atom, constraints: constraints}, _) when constraints != [] do
    case Keyword.get(constraints, :one_of) do
      nil -> "string"
      values -> values |> Enum.map(&"\"#{to_string(&1)}\"") |> Enum.join(" | ")
    end
  end

  def get_ts_type(%{type: Ash.Type.Atom}, _), do: "string"
  def get_ts_type(%{type: Ash.Type.String}, _), do: "string"
  def get_ts_type(%{type: Ash.Type.CiString}, _), do: "string"
  def get_ts_type(%{type: Ash.Type.Integer}, _), do: "number"
  def get_ts_type(%{type: Ash.Type.Float}, _), do: "number"
  def get_ts_type(%{type: Ash.Type.Decimal}, _), do: "Decimal"
  def get_ts_type(%{type: Ash.Type.Boolean}, _), do: "boolean"
  def get_ts_type(%{type: Ash.Type.UUID}, _), do: "UUID"
  def get_ts_type(%{type: Ash.Type.UUIDv7}, _), do: "UUIDv7"
  def get_ts_type(%{type: Ash.Type.Date}, _), do: "AshDate"
  def get_ts_type(%{type: Ash.Type.Time}, _), do: "Time"
  def get_ts_type(%{type: Ash.Type.TimeUsec}, _), do: "TimeUsec"
  def get_ts_type(%{type: Ash.Type.UtcDatetime}, _), do: "UtcDateTime"
  def get_ts_type(%{type: Ash.Type.UtcDatetimeUsec}, _), do: "UtcDateTimeUsec"
  def get_ts_type(%{type: Ash.Type.DateTime}, _), do: "DateTime"
  def get_ts_type(%{type: Ash.Type.NaiveDatetime}, _), do: "NaiveDateTime"
  def get_ts_type(%{type: Ash.Type.Duration}, _), do: "Duration"
  def get_ts_type(%{type: Ash.Type.DurationName}, _), do: "DurationName"
  def get_ts_type(%{type: Ash.Type.Binary}, _), do: "Binary"
  def get_ts_type(%{type: Ash.Type.UrlEncodedBinary}, _), do: "UrlEncodedBinary"
  def get_ts_type(%{type: Ash.Type.File}, _), do: "File"
  def get_ts_type(%{type: Ash.Type.Function}, _), do: "Function"
  def get_ts_type(%{type: Ash.Type.Term}, _), do: "any"
  def get_ts_type(%{type: Ash.Type.Vector}, _), do: "number[]"
  def get_ts_type(%{type: Ash.Type.Module}, _), do: "ModuleName"

  def get_ts_type(%{type: Ash.Type.Map, constraints: constraints}, select)
      when constraints != [] do
    case Keyword.get(constraints, :fields) do
      nil -> "Record<string, any>"
      fields -> build_map_type(fields, select)
    end
  end

  def get_ts_type(%{type: Ash.Type.Map}, _), do: "Record<string, any>"

  def get_ts_type(%{type: Ash.Type.Keyword, constraints: constraints}, _)
      when constraints != [] do
    case Keyword.get(constraints, :fields) do
      nil -> "Record<string, any>"
      fields -> build_map_type(fields)
    end
  end

  def get_ts_type(%{type: Ash.Type.Keyword}, _), do: "Record<string, any>"

  def get_ts_type(%{type: Ash.Type.Tuple, constraints: constraints}, _) do
    case Keyword.get(constraints, :fields) do
      nil -> "Record<string, any>"
      fields -> build_map_type(fields)
    end
  end

  def get_ts_type(%{type: Ash.Type.Struct, constraints: constraints}, select_and_loads) do
    instance_of = Keyword.get(constraints, :instance_of)
    fields = Keyword.get(constraints, :fields)

    cond do
      fields != nil ->
        # If fields are defined, create a typed object
        build_map_type(fields)

      instance_of != nil ->
        build_resource_type(instance_of, select_and_loads)

      true ->
        # Fallback to generic record type
        "Record<string, any>"
    end
  end

  def get_ts_type(%{type: Ash.Type.Union, constraints: constraints}, _) do
    case Keyword.get(constraints, :types) do
      nil -> "any"
      types -> build_union_type(types)
    end
  end

  def get_ts_type(%{type: {:array, inner_type}, constraints: constraints}, _) do
    inner_ts_type = get_ts_type(%{type: inner_type, constraints: constraints[:items] || []})
    "Array<#{inner_ts_type}>"
  end

  def get_ts_type(%{type: AshDoubleEntry.ULID}, _), do: "ULID"
  def get_ts_type(%{type: AshMoney.Types.Money}, _), do: "Money"

  # Handle atom types (shorthand versions)
  def get_ts_type(%{type: :string}, _), do: "string"
  def get_ts_type(%{type: :integer}, _), do: "number"
  def get_ts_type(%{type: :float}, _), do: "number"
  def get_ts_type(%{type: :decimal}, _), do: "Decimal"
  def get_ts_type(%{type: :boolean}, _), do: "boolean"
  def get_ts_type(%{type: :uuid}, _), do: "UUID"
  def get_ts_type(%{type: :date}, _), do: "Date"
  def get_ts_type(%{type: :time}, _), do: "Time"
  def get_ts_type(%{type: :datetime}, _), do: "DateTime"
  def get_ts_type(%{type: :naive_datetime}, _), do: "NaiveDateTime"
  def get_ts_type(%{type: :utc_datetime}, _), do: "UtcDateTime"
  def get_ts_type(%{type: :utc_datetime_usec}, _), do: "UtcDateTimeUsec"
  def get_ts_type(%{type: :binary}, _), do: "Binary"

  def get_ts_type(%{type: type, constraints: constraints} = attr, _) do
    cond do
      Ash.Type.NewType.new_type?(type) ->
        sub_type_constraints = Ash.Type.NewType.constraints(type, constraints)
        subtype = Ash.Type.NewType.subtype_of(type)
        get_ts_type(%{attr | type: subtype, constraints: sub_type_constraints})

      Spark.implements_behaviour?(type, Ash.Type.Enum) ->
        case type do
          module when is_atom(module) ->
            try do
              values = apply(module, :values, [])
              values |> Enum.map(&"\"#{to_string(&1)}\"") |> Enum.join(" | ")
            rescue
              _ -> "string"
            end

          _ ->
            "string"
        end

      true ->
        raise "unsupported type #{inspect(type)}"
    end
  end

  def build_map_type(fields, select \\ nil) do
    selected_fields =
      if select do
        Enum.filter(fields, fn {field_name, _} -> to_string(field_name) in select end)
      else
        fields
      end

    field_types =
      selected_fields
      |> Enum.map(fn {field_name, field_config} ->
        field_type =
          get_ts_type(%{type: field_config[:type], constraints: field_config[:constraints] || []})

        allow_nil = Keyword.get(field_config, :allow_nil?, true)
        optional = if allow_nil, do: "?", else: ""
        "#{field_name}#{optional}: #{field_type}"
      end)
      |> Enum.join(", ")

    "{#{field_types}}"
  end

  def build_union_type(types) do
    type_strings =
      types
      |> Enum.map(fn {_type_name, type_config} ->
        get_ts_type(%{type: type_config[:type], constraints: type_config[:constraints] || []})
      end)
      |> Enum.uniq()
      |> Enum.join(" | ")

    case type_strings do
      "" -> "any"
      single -> single
    end
  end

  def build_resource_type(resource, select_and_loads \\ nil)

  def build_resource_type(resource, nil) do
    field_types =
      Ash.Resource.Info.public_attributes(resource)
      |> Enum.map(fn attr ->
        get_resource_field_spec(attr.name, resource)
      end)
      |> Enum.join("\n")

    "{#{field_types}}"
  end

  def build_resource_type(resource, select_and_loads) do
    field_types =
      select_and_loads
      |> Enum.map(fn attr ->
        get_resource_field_spec(attr, resource)
      end)
      |> Enum.join("\n")

    "{#{field_types}}"
  end

  def get_resource_field_spec(field, resource) when is_atom(field) do
    attributes =
      if field == :id,
        do: [Ash.Resource.Info.attribute(resource, :id)],
        else: Ash.Resource.Info.public_attributes(resource)

    calculations = Ash.Resource.Info.public_calculations(resource)
    aggregates = Ash.Resource.Info.public_aggregates(resource)

    with nil <- Enum.find(attributes, &(&1.name == field)),
         nil <- Enum.find(calculations, &(&1.name == field)),
         nil <- Enum.find(aggregates, &(&1.name == field)) do
      throw("Field not found: #{resource}.#{field}" |> String.replace("Elixir.", ""))
    else
      %Ash.Resource.Attribute{} = attr ->
        if attr.allow_nil? do
          "  #{field}?: #{get_ts_type(attr)} | null;"
        else
          "  #{field}: #{get_ts_type(attr)};"
        end

      %Ash.Resource.Calculation{} = calc ->
        if calc.allow_nil? do
          "  #{field}?: #{get_ts_type(calc)} | null;"
        else
          "  #{field}: #{get_ts_type(calc)};"
        end

      %Ash.Resource.Aggregate{} = agg ->
        type =
          case agg.kind do
            :sum ->
              resource
              |> lookup_aggregate_type(agg.relationship_path, agg.field)
              |> get_ts_type()

            :first ->
              resource
              |> lookup_aggregate_type(agg.relationship_path, agg.field)
              |> get_ts_type()

            _ ->
              get_ts_type(agg.kind)
          end

        if agg.include_nil? do
          "  #{field}?: #{type} | null;"
        else
          "  #{field}: #{type};"
        end

      field ->
        throw("Unknown field type: #{inspect(field)}")
    end
  end

  def get_resource_field_spec({field_name, fields}, resource) do
    relationships = Ash.Resource.Info.public_relationships(resource)

    case Enum.find(relationships, &(&1.name == field_name)) do
      nil ->
        throw(
          "Relationship not found on #{resource}: #{field_name}"
          |> String.replace("Elixir.", "")
        )

      %Ash.Resource.Relationships.HasMany{} = rel ->
        id_fields = Ash.Resource.Info.primary_key(resource)
        fields = Enum.uniq(fields ++ id_fields)

        "  #{field_name}: {#{Enum.map_join(fields, "\n", &get_resource_field_spec(&1, rel.destination))}\n}[];\n"

      rel ->
        id_fields = Ash.Resource.Info.primary_key(resource)
        fields = Enum.uniq(fields ++ id_fields)

        if rel.allow_nil? do
          "  #{field_name}: {#{Enum.map_join(fields, "\n", &get_resource_field_spec(&1, rel.destination))}} | null;"
        else
          "  #{field_name}: {#{Enum.map_join(fields, "\n", &get_resource_field_spec(&1, rel.destination))}};\n"
        end
    end
  end

  def lookup_aggregate_type(current_resource, [], field) do
    Ash.Resource.Info.attribute(current_resource, field)
  end

  def lookup_aggregate_type(current_resource, relationship_path, field) do
    [next_resource | rest] = relationship_path

    relationship =
      Enum.find(Ash.Resource.Info.relationships(current_resource), &(&1.name == next_resource))

    lookup_aggregate_type(relationship.destination, rest, field)
  end
end
