-- nx_batch_execute: Transaction wrapper stored procedure for NexusStore
--
-- Deploy this function to your Supabase project to enable atomic batch
-- operations via SupabaseBackend.runInTransaction().
--
-- Each RPC call is already a PostgreSQL transaction, so all operations
-- within this function are atomic — if any operation fails, the entire
-- batch is rolled back automatically by PostgreSQL.
--
-- Usage from Dart:
--   await backend.runInTransaction(() async {
--     await backend.save(user);
--     await backend.save(profile);
--   });
--
-- This translates to a single RPC call:
--   SELECT nx_batch_execute('[ {"type":"upsert","table":"users","data":{...}}, ... ]'::jsonb);

CREATE OR REPLACE FUNCTION nx_batch_execute(operations jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  op jsonb;
  result jsonb;
  results jsonb := '[]'::jsonb;
  op_table text;
  op_type text;
  pk_col text;
BEGIN
  FOR op IN SELECT * FROM jsonb_array_elements(operations)
  LOOP
    op_type := op->>'type';
    op_table := op->>'table';
    pk_col := COALESCE(op->>'primary_key_column', 'id');

    CASE op_type
      WHEN 'upsert' THEN
        -- Insert or update a single row
        EXECUTE format(
          'INSERT INTO %I SELECT * FROM jsonb_populate_record(null::%I, $1)
           ON CONFLICT (%I) DO UPDATE SET ' ||
          (SELECT string_agg(format('%I = EXCLUDED.%I', key, key), ', ')
           FROM jsonb_object_keys(op->'data') AS key
           WHERE key != pk_col) ||
          ' RETURNING to_jsonb(%I.*)',
          op_table, op_table, pk_col, op_table
        ) INTO result USING op->'data';
        results := results || jsonb_build_array(result);

      WHEN 'delete' THEN
        -- Delete a single row by primary key
        EXECUTE format(
          'DELETE FROM %I WHERE %I = $1',
          op_table, pk_col
        ) USING (op->>'id');
        results := results || jsonb_build_array(
          jsonb_build_object('deleted', op->>'id')
        );

      WHEN 'delete_many' THEN
        -- Delete multiple rows by primary key
        EXECUTE format(
          'DELETE FROM %I WHERE %I = ANY(
            SELECT value::text FROM jsonb_array_elements_text($1)
          )',
          op_table, pk_col
        ) USING op->'ids';
        results := results || jsonb_build_array(
          jsonb_build_object('deleted', op->'ids')
        );

      ELSE
        RAISE EXCEPTION 'Unknown operation type: %', op_type;
    END CASE;
  END LOOP;

  RETURN results;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION nx_batch_execute(jsonb) TO authenticated;
