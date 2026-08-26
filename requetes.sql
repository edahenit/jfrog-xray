SELECT
  current_setting('max_connections')::int AS max_connections,
  count(*) AS current_connections,
  round(count(*) * 100.0
        / current_setting('max_connections')::int, 2) AS pct_used
FROM pg_stat_activity
WHERE backend_type = 'client backend';
