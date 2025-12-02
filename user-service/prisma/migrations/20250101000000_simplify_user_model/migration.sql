-- DropIndex
DROP INDEX IF EXISTS "users_email_key";

-- DropIndex
DROP INDEX IF EXISTS "users_username_key";

-- AlterTable
ALTER TABLE "users" DROP COLUMN IF EXISTS "email",
DROP COLUMN IF EXISTS "username",
DROP COLUMN IF EXISTS "password",
DROP COLUMN IF EXISTS "firstName",
DROP COLUMN IF EXISTS "lastName",
DROP COLUMN IF EXISTS "createdAt",
DROP COLUMN IF EXISTS "updatedAt";

-- Ensure balance column exists and has default
ALTER TABLE "users" ALTER COLUMN "balance" SET DEFAULT 0;
ALTER TABLE "users" ALTER COLUMN "balance" SET NOT NULL;
