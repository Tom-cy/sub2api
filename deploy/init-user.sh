#!/bin/bash
# init-user.sh - 初始化管理员用户

echo "Initializing admin user..."

docker exec -i postgresql psql -U root -d postgres <<'SQL'
-- 创建扩展
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 检查并添加唯一约束
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'users'::regclass
        AND conname = 'users_email_key'
    ) THEN
        -- 清理可能的重复数据
        WITH duplicates AS (
            SELECT DISTINCT ON (email) id, email
            FROM users
            ORDER BY email, created_at DESC
        )
        DELETE FROM users
        WHERE id NOT IN (SELECT id FROM duplicates);

        -- 添加唯一约束
        ALTER TABLE users ADD CONSTRAINT users_email_key UNIQUE (email);
        RAISE NOTICE 'Added unique constraint on email';
    END IF;
END $$;

-- 插入或更新管理员用户
INSERT INTO users (
    email,
    password_hash,
    role,
    balance,
    concurrency,
    status,
    created_at,
    updated_at
)
VALUES (
    'admin@sub2api.local',
    crypt('chen1995', gen_salt('bf')),
    'admin',
    0,
    5,
    'active',
    NOW(),
    NOW()
)
ON CONFLICT (email) DO UPDATE SET
    password_hash = EXCLUDED.password_hash,
    role = 'admin',
    status = 'active',
    updated_at = NOW();

SELECT 'Admin user initialized successfully!' as result;
SQL

echo "Done!"
