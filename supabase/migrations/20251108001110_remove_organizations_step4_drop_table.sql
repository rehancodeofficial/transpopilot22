/*
  # Remove Organizations - Step 4: Drop Organizations Table

  ## Overview
  Drops the organizations table entirely as it's no longer needed.

  ## Changes
  1. Drop the organizations table and all its dependencies

  ## Security
  - No impact on other tables as all foreign keys were already removed
  - System transitions to role-based access only

  ## Important Notes
  - This completes the removal of multi-tenancy
  - System now uses pure role-based access control
*/

-- Drop the organizations table
DROP TABLE IF EXISTS organizations CASCADE;