-- schemaVersion 1
---
CREATE TABLE "custom_exercises" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "equipment" INTEGER NOT NULL, "tracking" INTEGER NOT NULL, "primary_muscle" INTEGER NOT NULL, "notes" TEXT NULL, "archived" INTEGER NOT NULL DEFAULT 0 CHECK ("archived" IN (0, 1)), "created_at" INTEGER NOT NULL, PRIMARY KEY ("id"));
---
CREATE TABLE "local_settings" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, PRIMARY KEY ("key"));
---
CREATE TABLE "personal_records" ("id" TEXT NOT NULL, "exercise_id" TEXT NOT NULL, "workout_id" TEXT NOT NULL, "value" REAL NOT NULL, "previous" REAL NULL, "achieved_at" INTEGER NOT NULL, PRIMARY KEY ("id"));
---
CREATE TABLE "routine_exercises" ("id" TEXT NOT NULL, "routine_id" TEXT NOT NULL, "exercise_id" TEXT NOT NULL, "position" INTEGER NOT NULL DEFAULT 0, "sets" INTEGER NOT NULL DEFAULT 3, "rep_min" INTEGER NOT NULL DEFAULT 8, "rep_max" INTEGER NOT NULL DEFAULT 12, "target_seconds" INTEGER NULL, "rest_seconds" INTEGER NOT NULL DEFAULT 90, PRIMARY KEY ("id"));
---
CREATE TABLE "routines" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "sort_order" INTEGER NOT NULL DEFAULT 0, "archived" INTEGER NOT NULL DEFAULT 0 CHECK ("archived" IN (0, 1)), "created_at" INTEGER NOT NULL, PRIMARY KEY ("id"));
---
CREATE TABLE "unlocked_achievements" ("id" TEXT NOT NULL, "unlocked_at" INTEGER NOT NULL, "seen" INTEGER NOT NULL DEFAULT 0 CHECK ("seen" IN (0, 1)), PRIMARY KEY ("id"));
---
CREATE TABLE "workout_sets" ("id" TEXT NOT NULL, "workout_id" TEXT NOT NULL, "exercise_id" TEXT NOT NULL, "exercise_order" INTEGER NOT NULL, "set_index" INTEGER NOT NULL, "weight_kg" REAL NULL, "reps" INTEGER NULL, "seconds" INTEGER NULL, "done" INTEGER NOT NULL DEFAULT 0 CHECK ("done" IN (0, 1)), "completed_at" INTEGER NULL, "rep_min" INTEGER NULL, "rep_max" INTEGER NULL, "rest_seconds" INTEGER NULL, PRIMARY KEY ("id"));
---
CREATE TABLE "workouts" ("id" TEXT NOT NULL, "routine_id" TEXT NULL, "name" TEXT NOT NULL, "started_at" INTEGER NOT NULL, "finished_at" INTEGER NULL, "note" TEXT NULL, PRIMARY KEY ("id"));
---
CREATE INDEX idx_routine_exercises_routine ON routine_exercises (routine_id, position);
---
CREATE INDEX idx_workout_sets_exercise ON workout_sets (exercise_id, done);
---
CREATE INDEX idx_workout_sets_workout ON workout_sets (workout_id, exercise_order, set_index);
---
CREATE INDEX idx_workouts_started ON workouts (started_at);
