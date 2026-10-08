-- =====================================================================
--  SWE3003 practice database  (generated file: edit practice_build/, not this)
--
--  Run once on the school server, inside psql:
--      \i ~/practice/setup.sql
--  Re-running it resets everything (data, your views/functions in the
--  practice schema, and your progress).
--
--  Everything lives in its own schema called "practice", so it never
--  touches the tables in "public".
-- =====================================================================
set client_min_messages = warning;

drop schema if exists practice cascade;
create schema practice;
set search_path to practice;

-- ---------------------------------------------------------------------
-- University schema (same shape as the textbook / lecture slides)
-- ---------------------------------------------------------------------
create table classroom
  (building     varchar(15),
   room_number  varchar(7),
   capacity     numeric(4,0),
   primary key (building, room_number));

create table department
  (dept_name    varchar(20),
   building     varchar(15),
   budget       numeric(12,2) check (budget > 0),
   primary key (dept_name));

create table course
  (course_id    varchar(8),
   title        varchar(50),
   dept_name    varchar(20),
   credits      numeric(2,0) check (credits > 0),
   primary key (course_id),
   foreign key (dept_name) references department on delete set null);

create table instructor
  (ID           varchar(5),
   name         varchar(20) not null,
   dept_name    varchar(20),
   salary       numeric(8,2) check (salary > 29000),
   primary key (ID),
   foreign key (dept_name) references department on delete set null);

create table section
  (course_id    varchar(8),
   sec_id       varchar(8),
   semester     varchar(6) check (semester in ('Fall', 'Winter', 'Spring', 'Summer')),
   year         numeric(4,0) check (year > 1701 and year < 2100),
   building     varchar(15),
   room_number  varchar(7),
   time_slot_id varchar(4),
   primary key (course_id, sec_id, semester, year),
   foreign key (course_id) references course on delete cascade,
   foreign key (building, room_number) references classroom on delete set null);

create table teaches
  (ID           varchar(5),
   course_id    varchar(8),
   sec_id       varchar(8),
   semester     varchar(6),
   year         numeric(4,0),
   primary key (ID, course_id, sec_id, semester, year),
   foreign key (course_id, sec_id, semester, year) references section on delete cascade,
   foreign key (ID) references instructor on delete cascade);

create table student
  (ID           varchar(5),
   name         varchar(20) not null,
   dept_name    varchar(20),
   tot_cred     numeric(3,0) check (tot_cred >= 0),
   primary key (ID),
   foreign key (dept_name) references department on delete set null);

create table takes
  (ID           varchar(5),
   course_id    varchar(8),
   sec_id       varchar(8),
   semester     varchar(6),
   year         numeric(4,0),
   grade        varchar(2),
   primary key (ID, course_id, sec_id, semester, year),
   foreign key (course_id, sec_id, semester, year) references section on delete cascade,
   foreign key (ID) references student on delete cascade);

create table advisor
  (s_ID         varchar(5),
   i_ID         varchar(5),
   primary key (s_ID),
   foreign key (i_ID) references instructor (ID) on delete set null,
   foreign key (s_ID) references student (ID) on delete cascade);

create table time_slot
  (time_slot_id varchar(4),
   day          varchar(1),
   start_hr     numeric(2) check (start_hr >= 0 and start_hr < 24),
   start_min    numeric(2) check (start_min >= 0 and start_min < 60),
   end_hr       numeric(2) check (end_hr >= 0 and end_hr < 24),
   end_min      numeric(2) check (end_min >= 0 and end_min < 60),
   primary key (time_slot_id, day, start_hr, start_min));

create table prereq
  (course_id    varchar(8),
   prereq_id    varchar(8),
   primary key (course_id, prereq_id),
   foreign key (course_id) references course on delete cascade,
   foreign key (prereq_id) references course);

-- ---------------------------------------------------------------------
-- Data.  The current term is Fall 2026; a takes row with grade NULL
-- means the course is still in progress.
-- ---------------------------------------------------------------------
insert into classroom values
  ('Packard', '101', 500),
  ('Painter', '514', 10),
  ('Taylor', '3128', 70),
  ('Watson', '100', 30),
  ('Watson', '120', 50);

insert into department values
  ('Biology', 'Watson', 90000),
  ('Comp. Sci.', 'Taylor', 100000),
  ('Elec. Eng.', 'Taylor', 85000),
  ('Finance', 'Painter', 120000),
  ('History', 'Painter', 50000),
  ('Music', 'Packard', 80000),
  ('Physics', 'Watson', 70000),
  ('Mathematics', 'Taylor', 60000);       -- no instructors, students or courses

insert into course values
  ('BIO-101', 'Intro. to Biology', 'Biology', 4),
  ('BIO-301', 'Genetics', 'Biology', 4),
  ('BIO-399', 'Computational Biology', 'Biology', 3),   -- never offered
  ('CS-101', 'Intro. to Computer Science', 'Comp. Sci.', 4),
  ('CS-190', 'Game Design', 'Comp. Sci.', 4),
  ('CS-315', 'Robotics', 'Comp. Sci.', 3),
  ('CS-319', 'Image Processing', 'Comp. Sci.', 3),
  ('CS-347', 'Database System Concepts', 'Comp. Sci.', 3),
  ('EE-181', 'Intro. to Digital Systems', 'Elec. Eng.', 3),
  ('FIN-201', 'Investment Banking', 'Finance', 3),
  ('HIS-351', 'World History', 'History', 3),
  ('MU-199', 'Music Video Production', 'Music', 3),
  ('PHY-101', 'Physical Principles', 'Physics', 4);

insert into instructor values
  ('10101', 'Srinivasan', 'Comp. Sci.', 65000),
  ('12121', 'Wu', 'Finance', 90000),
  ('15151', 'Mozart', 'Music', 40000),
  ('22222', 'Einstein', 'Physics', 95000),
  ('32343', 'El Said', 'History', 60000),
  ('33456', 'Gold', 'Physics', 87000),
  ('45565', 'Katz', 'Comp. Sci.', 75000),
  ('58583', 'Califieri', 'History', 62000),
  ('76543', 'Singh', 'Finance', 80000),
  ('76766', 'Crick', 'Biology', 72000),
  ('83821', 'Brandt', 'Comp. Sci.', 92000),
  ('98345', 'Kim', 'Elec. Eng.', 80000),
  ('44444', 'Park', 'Elec. Eng.', null);  -- new hire, salary not set yet

insert into section values
  ('BIO-101', '1', 'Summer', 2025, 'Painter', '514', 'B'),
  ('BIO-301', '1', 'Summer', 2026, 'Painter', '514', 'A'),
  ('CS-101', '1', 'Fall', 2025, 'Packard', '101', 'H'),
  ('CS-101', '1', 'Spring', 2026, 'Packard', '101', 'F'),
  ('CS-190', '1', 'Spring', 2025, 'Taylor', '3128', 'E'),
  ('CS-190', '2', 'Spring', 2025, 'Taylor', '3128', 'A'),
  ('CS-315', '1', 'Spring', 2026, 'Watson', '120', 'D'),
  ('CS-319', '1', 'Spring', 2026, 'Watson', '100', 'B'),
  ('CS-319', '2', 'Spring', 2026, 'Taylor', '3128', 'C'),
  ('CS-347', '1', 'Fall', 2025, 'Taylor', '3128', 'A'),
  ('EE-181', '1', 'Spring', 2025, 'Taylor', '3128', 'C'),
  ('FIN-201', '1', 'Spring', 2026, 'Packard', '101', 'B'),
  ('HIS-351', '1', 'Spring', 2026, 'Painter', '514', 'C'),
  ('MU-199', '1', 'Spring', 2026, 'Packard', '101', 'D'),
  ('PHY-101', '1', 'Fall', 2025, 'Watson', '100', 'A'),
  -- current term
  ('CS-101', '1', 'Fall', 2026, 'Packard', '101', 'H'),
  ('CS-347', '1', 'Fall', 2026, 'Taylor', '3128', 'A'),
  ('CS-319', '1', 'Fall', 2026, 'Watson', '100', 'B'),   -- no instructor, no students
  ('PHY-101', '1', 'Fall', 2026, null, null, 'C'),       -- no classroom yet
  ('MU-199', '1', 'Fall', 2026, 'Painter', '514', 'D');

insert into teaches values
  ('10101', 'CS-101', '1', 'Fall', 2025),
  ('10101', 'CS-315', '1', 'Spring', 2026),
  ('10101', 'CS-347', '1', 'Fall', 2025),
  ('12121', 'FIN-201', '1', 'Spring', 2026),
  ('15151', 'MU-199', '1', 'Spring', 2026),
  ('22222', 'PHY-101', '1', 'Fall', 2025),
  ('32343', 'HIS-351', '1', 'Spring', 2026),
  ('45565', 'CS-101', '1', 'Spring', 2026),
  ('45565', 'CS-319', '1', 'Spring', 2026),
  ('76766', 'BIO-101', '1', 'Summer', 2025),
  ('76766', 'BIO-301', '1', 'Summer', 2026),
  ('83821', 'CS-190', '1', 'Spring', 2025),
  ('83821', 'CS-190', '2', 'Spring', 2025),
  ('83821', 'CS-319', '2', 'Spring', 2026),
  ('98345', 'EE-181', '1', 'Spring', 2025),
  -- current term (CS-101 has two instructors)
  ('10101', 'CS-101', '1', 'Fall', 2026),
  ('45565', 'CS-101', '1', 'Fall', 2026),
  ('83821', 'CS-347', '1', 'Fall', 2026),
  ('22222', 'PHY-101', '1', 'Fall', 2026),
  ('15151', 'MU-199', '1', 'Fall', 2026);

insert into student values
  ('00128', 'Zhang', 'Comp. Sci.', 102),
  ('12345', 'Shankar', 'Comp. Sci.', 32),
  ('19991', 'Brandt', 'History', 80),
  ('23121', 'Chavez', 'Finance', 110),
  ('44553', 'Peltier', 'Physics', 56),
  ('45678', 'Levy', 'Physics', 46),
  ('54321', 'Williams', 'Comp. Sci.', 54),
  ('55739', 'Sanchez', 'Music', 38),
  ('70557', 'Snow', 'Physics', 0),        -- has never taken a course
  ('76543', 'Brown', 'Comp. Sci.', 58),
  ('76653', 'Aoi', 'Elec. Eng.', 60),
  ('98765', 'Bourikas', 'Elec. Eng.', 98),
  ('98988', 'Tanaka', 'Biology', 120),
  ('66666', 'Ortiz', null, 0);            -- no department, no courses

insert into takes values
  ('00128', 'CS-101', '1', 'Fall', 2025, 'A'),
  ('00128', 'CS-347', '1', 'Fall', 2025, 'A-'),
  ('12345', 'CS-101', '1', 'Fall', 2025, 'C'),
  ('12345', 'CS-190', '2', 'Spring', 2025, 'A'),
  ('12345', 'CS-315', '1', 'Spring', 2026, 'A'),
  ('12345', 'CS-347', '1', 'Fall', 2025, 'A'),
  ('19991', 'HIS-351', '1', 'Spring', 2026, 'B'),
  ('23121', 'FIN-201', '1', 'Spring', 2026, 'C+'),
  ('44553', 'PHY-101', '1', 'Fall', 2025, 'B-'),
  ('45678', 'CS-101', '1', 'Fall', 2025, 'F'),
  ('45678', 'CS-101', '1', 'Spring', 2026, 'B+'),
  ('45678', 'CS-319', '1', 'Spring', 2026, 'B'),
  ('54321', 'CS-101', '1', 'Fall', 2025, 'A-'),
  ('54321', 'CS-190', '2', 'Spring', 2025, 'B+'),
  ('55739', 'MU-199', '1', 'Spring', 2026, 'A-'),
  ('76543', 'CS-101', '1', 'Fall', 2025, 'A'),
  ('76543', 'CS-319', '2', 'Spring', 2026, 'A'),
  ('76653', 'EE-181', '1', 'Spring', 2025, 'C'),
  ('98765', 'CS-101', '1', 'Fall', 2025, 'C-'),
  ('98765', 'CS-315', '1', 'Spring', 2026, 'B'),
  ('98988', 'BIO-101', '1', 'Summer', 2025, 'A'),
  ('98988', 'BIO-301', '1', 'Summer', 2026, 'A-'),
  -- current term: grade NULL = in progress
  ('19991', 'CS-101', '1', 'Fall', 2026, null),
  ('55739', 'CS-101', '1', 'Fall', 2026, null),
  ('76653', 'CS-101', '1', 'Fall', 2026, null),
  ('45678', 'CS-347', '1', 'Fall', 2026, null),
  ('54321', 'CS-347', '1', 'Fall', 2026, null),
  ('98765', 'CS-347', '1', 'Fall', 2026, null),
  ('12345', 'PHY-101', '1', 'Fall', 2026, null),
  ('44553', 'MU-199', '1', 'Fall', 2026, null);

insert into advisor values
  ('00128', '45565'),
  ('12345', '10101'),
  ('23121', '76543'),
  ('44553', '22222'),
  ('45678', '22222'),
  ('76543', '45565'),
  ('76653', '98345'),
  ('98765', '98345'),
  ('98988', '76766');

insert into time_slot values
  ('A', 'M', 8, 0, 8, 50),   ('A', 'W', 8, 0, 8, 50),   ('A', 'F', 8, 0, 8, 50),
  ('B', 'M', 9, 0, 9, 50),   ('B', 'W', 9, 0, 9, 50),   ('B', 'F', 9, 0, 9, 50),
  ('C', 'M', 11, 0, 11, 50), ('C', 'W', 11, 0, 11, 50), ('C', 'F', 11, 0, 11, 50),
  ('D', 'M', 13, 0, 13, 50), ('D', 'W', 13, 0, 13, 50), ('D', 'F', 13, 0, 13, 50),
  ('E', 'T', 10, 30, 11, 45), ('E', 'R', 10, 30, 11, 45),
  ('F', 'T', 14, 30, 15, 45), ('F', 'R', 14, 30, 15, 45),
  ('G', 'M', 16, 0, 16, 50), ('G', 'W', 16, 0, 16, 50), ('G', 'F', 16, 0, 16, 50),
  ('H', 'W', 10, 0, 12, 30);

insert into prereq values
  ('BIO-301', 'BIO-101'),
  ('BIO-399', 'BIO-101'),
  ('BIO-399', 'BIO-301'),
  ('CS-190', 'CS-101'),
  ('CS-315', 'CS-101'),
  ('CS-319', 'CS-101'),
  ('CS-347', 'CS-101'),
  ('CS-347', 'CS-190'),
  ('EE-181', 'PHY-101');

-- ---------------------------------------------------------------------
-- Shop schema (seller, item, buyer, orders, order_details).
-- ORDER is a reserved word in SQL (ORDER BY), so the orders table is "orders".
-- ---------------------------------------------------------------------
create table seller
  (seller_id    int primary key,
   seller_name  varchar(30) not null,
   city         varchar(20));

create table item
  (item_id      int primary key,
   item_name    varchar(30) not null,
   price        numeric(8,2));

create table buyer
  (buyer_id     int primary key,
   buyer_name   varchar(30) not null,
   street       varchar(40),
   city         varchar(20),
   phone        varchar(15));

create table orders
  (order_no     int primary key,
   seller_id    int,
   buyer_id     int,
   received     date,
   shipped      char(1) check (shipped in ('Y', 'N')),
   foreign key (seller_id) references seller (seller_id) on delete cascade,
   foreign key (buyer_id) references buyer (buyer_id) on delete cascade);

create table order_details
  (order_no     int,
   item_id      int,
   qty          int check (qty > 0),
   primary key (order_no, item_id),
   foreign key (order_no) references orders (order_no) on delete cascade,
   foreign key (item_id) references item (item_id) on delete cascade);

insert into seller values
  (1, 'Kim Electronics', 'Seoul'),
  (2, 'Busan Books', 'Busan'),
  (3, 'Suwon Sports', 'Suwon'),
  (4, 'Daegu Deals', 'Daegu'),            -- has never received an order
  (5, 'Seoul Snacks', 'Seoul');

insert into item values
  (101, 'Laptop', 1200.00),
  (102, 'Mouse', 25.50),
  (103, 'Keyboard', 45.00),
  (104, 'Monitor', 300.00),
  (105, 'Textbook', 35.00),
  (106, 'Basketball', 30.00),
  (107, 'Snack Box', 12.00),
  (108, 'Webcam', 60.00),                 -- never ordered
  (109, 'Tent', 150.00);                  -- never ordered

insert into buyer values
  (1, 'Alice', '12 Main St', 'Seoul', '010-1111-1111'),
  (2, 'Bob', '5 Beach Rd', 'Busan', '010-2222-2222'),
  (3, 'Chris', '7 Hill St', 'Suwon', null),        -- no phone
  (4, 'Dana', '99 River Rd', 'Seoul', '010-4444-4444'),
  (5, 'Evan', '3 Park Ave', 'Incheon', '010-5555-5555'),  -- no orders
  (6, 'Fiona', '21 Lake St', 'Daegu', '010-6666-6666'),
  (7, 'Alice', '8 Oak St', 'Busan', '010-7777-7777');    -- a second Alice

insert into orders values
  (1001, 1, 1, '2026-03-02', 'Y'),
  (1002, 1, 2, '2026-03-05', 'Y'),
  (1003, 2, 1, '2026-03-07', 'Y'),
  (1004, 3, 3, '2026-03-10', 'N'),
  (1005, 1, 4, '2026-03-12', 'Y'),
  (1006, 5, 4, '2026-03-15', 'Y'),
  (1007, 2, 2, '2026-03-20', 'N'),
  (1008, 3, 6, '2026-04-01', 'Y'),
  (1009, 1, 1, '2026-04-03', 'N'),
  (1010, 5, 7, '2026-04-05', 'Y'),
  (1011, 2, 6, '2026-04-08', 'Y'),
  (1012, 1, 3, '2026-04-10', 'Y');

insert into order_details values
  (1001, 101, 1), (1001, 102, 2),
  (1002, 102, 15), (1002, 103, 1),
  (1003, 105, 3),
  (1004, 106, 2),
  (1005, 104, 2), (1005, 102, 1), (1005, 103, 1),
  (1006, 107, 20),
  (1007, 105, 12),
  (1008, 106, 1),
  (1009, 101, 1), (1009, 104, 1), (1009, 103, 1),
  (1010, 107, 5),
  (1011, 105, 1), (1011, 106, 11),
  (1012, 102, 30);

-- ---------------------------------------------------------------------
-- Extra tables used by the PL/pgSQL exercises (set G)
-- ---------------------------------------------------------------------
create table salary_log
  (ID           varchar(5),
   old_salary   numeric(8,2),
   new_salary   numeric(8,2),
   changed_at   timestamp default now());

create table dept_stats
  (dept_name       varchar(20) primary key,
   num_instructors integer not null,
   total_salary    numeric(12,2) not null);

-- Rebuilds dept_stats from scratch (used before the G7 test script).
create function resync_dept_stats() returns void
language sql
set search_path = practice
as $$
  delete from dept_stats;
  insert into dept_stats
    select d.dept_name, count(i.ID), coalesce(sum(i.salary), 0)
    from department d left join instructor i on i.dept_name = d.dept_name
    group by d.dept_name;
$$;
select resync_dept_stats();

-- ---------------------------------------------------------------------
-- The checker
--   select submit('A1', $$ your query here $$);
-- It runs your query and the reference query on the current data and
-- compares the rows (and the row order, when the question asks for one).
-- ---------------------------------------------------------------------
create table answer_key
  (seq       serial,
   qid       varchar(10) primary key,
   ordered   boolean not null,
   ref       text not null,           -- reference query, base64 so it does not spoil you
   title     text,
   question  text,
   hint      text,
   check_sql text,                    -- if set: your code is run first, then THIS is graded
   explain   text);                   -- solution explanation, base64

create table attempts
  (qid      varchar(10),
   passed   boolean,
   tried_at timestamp default now(),
   sql_text text);

create function b64d(t text) returns text
language sql immutable
as $$ select nullif(convert_from(decode(t, 'base64'), 'UTF8'), '') $$;

-- Rows of one table as {"name", "columns", "rows"} (all values as text), for the website.
create function table_preview(tname text)
returns json
language plpgsql
set search_path = practice
as $fn$
declare
  col_list  text;
  col_names json;
  rows_json json;
begin
  select string_agg(format('%I::text', column_name), ', ' order by ordinal_position),
         json_agg(column_name order by ordinal_position)
    into col_list, col_names
  from information_schema.columns
  where table_schema = 'practice' and table_name = tname;
  if col_list is null then
    return null;
  end if;
  execute format('select coalesce(json_agg(json_build_array(%s)), ''[]'') from (select * from %I order by 1) t',
                 col_list, tname)
    into rows_json;
  return json_build_object('name', tname, 'columns', col_names, 'rows', rows_json);
end;
$fn$;

-- Test drivers for the trigger questions: they reset the data they touch,
-- run the test statements (firing YOUR trigger), and return the result.
create function g6_test()
returns table (r_id varchar, r_old numeric, r_new numeric)
language plpgsql
set search_path = practice
as $fn$
begin
  update instructor set salary = 95000 where ID = '22222';
  update instructor set salary = 87000 where ID = '33456';
  update instructor set salary = null  where ID = '44444';
  delete from salary_log;
  update instructor set salary = salary + 1000 where ID in ('22222', '33456');
  update instructor set salary = 70000 where ID = '44444';
  update instructor set dept_name = 'Elec. Eng.' where ID = '98345';   -- salary unchanged
  return query select l.ID, l.old_salary, l.new_salary from salary_log l;
end;
$fn$;

create function g7_test(move_mozart boolean default false)
returns setof dept_stats
language plpgsql
set search_path = practice
as $fn$
begin
  delete from instructor where ID in ('60001', '60002');
  update instructor set dept_name = 'Music', salary = 40000 where ID = '15151';
  perform resync_dept_stats();
  insert into instructor values ('60001', 'Noether', 'Mathematics', null);
  insert into instructor values ('60002', 'Gauss', 'Mathematics', 99000);
  update instructor set salary = salary + 5000 where dept_name = 'Music';
  if move_mozart then
    update instructor set dept_name = 'Mathematics' where ID = '15151';
  end if;
  return query select * from dept_stats;
end;
$fn$;

create function submit(q_id varchar, sql_text text, src text default null)
returns setof text
language plpgsql
set search_path = practice
as $fn$
declare
  k         record;
  user_sql  text;
  ref_sql   text;
  mine      text[];
  expected  text[];
  same_rows boolean;
  extra     text;
  missing   text;
  wrapper   constant text := E'select coalesce(array_agg(_r::text), ''{}'') from (\n%s\n) _r';
begin
  select a.qid, a.ordered, a.ref into k
  from answer_key a
  where a.qid = upper(trim(q_id));
  if not found then
    return next format('No question called "%s". IDs look like A1, C4, G2, L1.3.', q_id);
    return;
  end if;

  user_sql := rtrim(sql_text, E' \t\r\n;');
  ref_sql  := rtrim(convert_from(decode(k.ref, 'base64'), 'UTF8'), E' \t\r\n;');

  if btrim(user_sql, E' \t\r\n') = '' then
    return next format('-     %s  (empty, skipped)', k.qid);
    return;
  end if;

  begin
    execute format(wrapper, user_sql) into mine;
  exception when others then
    insert into attempts (qid, passed, sql_text) values (k.qid, false, coalesce(src, sql_text));
    return next 'X  SQL error: ' || sqlerrm;
    return next '   Your query did not run. Run it on its own in psql to see the full error.';
    return;
  end;

  execute format(wrapper, ref_sql) into expected;

  same_rows := array(select x from unnest(mine) as u(x) order by x)
             = array(select x from unnest(expected) as u(x) order by x);

  if same_rows and (not k.ordered or mine = expected) then
    insert into attempts (qid, passed, sql_text) values (k.qid, true, coalesce(src, sql_text));
    return next format('PASS  %s  (%s row%s)', k.qid, cardinality(mine),
                       case when cardinality(mine) = 1 then '' else 's' end);
    return;
  end if;

  insert into attempts (qid, passed, sql_text) values (k.qid, false, coalesce(src, sql_text));
  if same_rows then
    return next 'X  Right rows, wrong order. Re-read how the question wants the rows sorted.';
    return;
  end if;

  return next format('X  Not quite. Your query returned %s row(s); expected %s row(s) (or the values differ).',
                     cardinality(mine), cardinality(expected));
  select string_agg(x, '  ') into extra
  from (select x
        from (select unnest(mine) as x except all select unnest(expected)) d
        order by x limit 4) e;
  select string_agg(x, '  ') into missing
  from (select x
        from (select unnest(expected) as x except all select unnest(mine)) d
        order by x limit 4) e;
  if extra is not null then
    return next '   Rows you have that should NOT be there: ' || extra;
  end if;
  if missing is not null then
    return next '   Rows that are MISSING from yours:       ' || missing;
  end if;
  return next '   Rows print as (col1,col2,...). An empty slot means NULL. Column order matters.';
end;
$fn$;

create view progress as
select k.qid as question,
       case when bool_or(a.passed) then 'PASS'
            when count(a.qid) > 0 then 'tried ' || count(a.qid) || 'x'
            else '' end as status
from answer_key k left join attempts a on a.qid = k.qid
group by k.seq, k.qid
order by k.seq;

create view score as
select count(*) filter (where status = 'PASS') as passed, count(*) as total
from progress;

-- Self-test: runs every reference query through submit().
create function verify_key()
returns table (question varchar, result text)
language plpgsql
set search_path = practice
as $fn$
declare
  k record;
begin
  for k in select a.qid, a.ref from answer_key a order by a.seq loop
    question := k.qid;
    begin
      select string_agg(s, ' ') into result
      from submit(k.qid, convert_from(decode(k.ref, 'base64'), 'UTF8')) as s;
    exception when others then
      result := 'BROKEN: ' || sqlerrm;
    end;
    return next;
  end loop;
  delete from attempts;
end;
$fn$;

-- ---------------------------------------------------------------------
-- Answer key (generated)
-- ---------------------------------------------------------------------
insert into answer_key (qid, ordered, ref, title, question, hint, check_sql, explain) values
  ('A1', false, 'c2VsZWN0IG5hbWUKZnJvbSBpbnN0cnVjdG9yCndoZXJlIGRlcHRfbmFtZSA9ICdDb21wLiBTY2kuJzsK', b64d('SW5zdHJ1Y3RvcnMgaW4gQ29tcC4gU2NpLg=='), b64d('TmFtZXMgb2YgYWxsIGluc3RydWN0b3JzIGluIHRoZSBgJ0NvbXAuIFNjaS4nYCBkZXBhcnRtZW50LgpPdXRwdXQ6IChuYW1lKQ=='), b64d('QSBwbGFpbiBgd2hlcmUgZGVwdF9uYW1lID0gLi4uYC4='), b64d(''), 'VGhlIHNpbXBsZXN0IHNoYXBlIG9mIGV2ZXJ5IHF1ZXJ5OiBgc2VsZWN0YCBwaWNrcyBjb2x1bW5zIChwcm9qZWN0aW9uLCDPgCksIGBmcm9tYCBuYW1lcyB0aGUgdGFibGUsIGB3aGVyZWAga2VlcHMgdGhlIHJvd3Mgd2hvc2UgY29uZGl0aW9uIGlzIHRydWUgKHNlbGVjdGlvbiwgz4MpLiBJbiByZWxhdGlvbmFsIGFsZ2VicmE6IM+APHN1Yj5uYW1lPC9zdWI+KM+DPHN1Yj5kZXB0X25hbWU9J0NvbXAuIFNjaS4nPC9zdWI+KGluc3RydWN0b3IpKS4KClN0cmluZyBjb25zdGFudHMgdXNlIHNpbmdsZSBxdW90ZXMuIERvdWJsZSBxdW90ZXMgbWVhbiBhbiBpZGVudGlmaWVyIChhIGNvbHVtbiBvciB0YWJsZSBuYW1lKSBpbiBQb3N0Z3JlU1FMLCBzbyBgIkNvbXAuIFNjaS4iYCB3b3VsZCBiZSBhbiBlcnJvci4='),
  ('A2', false, 'c2VsZWN0IGRpc3RpbmN0IGRlcHRfbmFtZQpmcm9tIGluc3RydWN0b3I7Cg==', b64d('RGVwYXJ0bWVudHMgdGhhdCBoYXZlIGluc3RydWN0b3Jz'), b64d('RXZlcnkgZGVwYXJ0bWVudCBuYW1lIHRoYXQgaGFzIGF0IGxlYXN0IG9uZSBpbnN0cnVjdG9yLCB3aXRob3V0IGR1cGxpY2F0ZXMuCk91dHB1dDogKGRlcHRfbmFtZSk='), b64d('TG9vayBpbiBgaW5zdHJ1Y3RvcmAsIG5vdCBgZGVwYXJ0bWVudGAu'), b64d(''), 'U1FMIGtlZXBzIGR1cGxpY2F0ZXMgYnkgZGVmYXVsdCAoYSBxdWVyeSByZXN1bHQgaXMgYSBtdWx0aXNldCkuIGBkaXN0aW5jdGAgcmVtb3ZlcyB0aGVtLiBSZWxhdGlvbmFsIGFsZ2VicmEncyDPgCByZW1vdmVzIGR1cGxpY2F0ZXMgYXV0b21hdGljYWxseTsgU1FMJ3MgYHNlbGVjdGAgZG9lcyBub3Qu'),
  ('A3', true, 'c2VsZWN0IElELCBuYW1lLCByb3VuZChzYWxhcnkgLyAxMiwgMikgYXMgbW9udGhseQpmcm9tIGluc3RydWN0b3IKd2hlcmUgc2FsYXJ5IGJldHdlZW4gNzAwMDAgYW5kIDkwMDAwCm9yZGVyIGJ5IG1vbnRobHkgZGVzYywgbmFtZTsK', b64d('TW9udGhseSBzYWxhcnksIHNvcnRlZA=='), b64d('Rm9yIGluc3RydWN0b3JzIHdob3NlIHNhbGFyeSBpcyBiZXR3ZWVuIDcwMDAwIGFuZCA5MDAwMCAoaW5jbHVzaXZlKTogdGhlaXIgSUQsIG5hbWUsIGFuZCBtb250aGx5IHNhbGFyeSAoYHNhbGFyeSAvIDEyYCByb3VuZGVkIHRvIDIgZGVjaW1hbHMpLgpPdXRwdXQ6IChJRCwgbmFtZSwgbW9udGhseSkgwrcgKipPcmRlcjoqKiBtb250aGx5IGRlc2NlbmRpbmcsIHRoZW4gbmFtZSBhc2NlbmRpbmc='), b64d('WW91IGNhbiB1c2UgdGhlIGFsaWFzIGBtb250aGx5YCBpbiBgb3JkZXIgYnlgLg=='), b64d(''), 'LSBgYmV0d2VlbiBhIGFuZCBiYCBpcyBpbmNsdXNpdmUgb24gYm90aCBlbmRzOiBzYW1lIGFzIGBzYWxhcnkgPj0gNzAwMDAgYW5kIHNhbGFyeSA8PSA5MDAwMGAuCi0gYHJvdW5kKHgsIDIpYCByb3VuZHMgdG8gMiBkZWNpbWFscy4gYHNhbGFyeSAvIDEyYCBrZWVwcyB0aGUgZnJhY3Rpb24gYmVjYXVzZSBzYWxhcnkgaXMgYG51bWVyaWNgLgotIGBvcmRlciBieSBtb250aGx5IGRlc2MsIG5hbWVgOiBzb3J0IGJ5IHRoZSBmaXJzdCBrZXksIGFuZCBvbmx5IHdoZW4gdHdvIHJvd3MgdGllIChLaW0gYW5kIFNpbmdoIGJvdGggZWFybiA4MDAwMCkgdXNlIHRoZSBzZWNvbmQga2V5LiBgZGVzY2AgYXBwbGllcyBvbmx5IHRvIHRoZSBjb2x1bW4gcmlnaHQgYmVmb3JlIGl0OyBgbmFtZWAgaXMgYXNjZW5kaW5nICh0aGUgZGVmYXVsdCkuCi0gWW91IGNhbiB1c2UgdGhlIG91dHB1dCBhbGlhcyAoYG1vbnRobHlgKSBpbiBgb3JkZXIgYnlgIGJlY2F1c2UgYG9yZGVyIGJ5YCBydW5zIGFmdGVyIGBzZWxlY3RgLiBZb3UgY2Fubm90IHVzZSBpdCBpbiBgd2hlcmVgLg=='),
  ('A4', false, 'c2VsZWN0IGNvdXJzZV9pZCwgdGl0bGUKZnJvbSBjb3Vyc2UKd2hlcmUgdGl0bGUgbGlrZSAnJUludHJvJSc7Cg==', b64d('VGl0bGVzIGNvbnRhaW5pbmcgIkludHJvIg=='), b64d('Q291cnNlcyB3aG9zZSB0aXRsZSBjb250YWlucyBgSW50cm9gLgpPdXRwdXQ6IChjb3Vyc2VfaWQsIHRpdGxlKQ=='), b64d('YGxpa2UgJyUuLi4lJ2A='), b64d(''), 'YCVgIG1hdGNoZXMgYW55IHN0cmluZyAoaW5jbHVkaW5nIHRoZSBlbXB0eSBvbmUpLiBgJyVJbnRybyUnYCA9ICJJbnRybyBhbnl3aGVyZSIuIGBsaWtlYCBpcyBjYXNlLXNlbnNpdGl2ZSBpbiBQb3N0Z3JlU1FMLCBzbyBgJyVpbnRybyUnYCB3b3VsZCBmaW5kIG5vdGhpbmcgaGVyZS4='),
  ('A5', false, 'c2VsZWN0IElELCBuYW1lCmZyb20gc3R1ZGVudAp3aGVyZSBuYW1lIGxpa2UgJ1NfX19fJSc7Cg==', b64d('TmFtZXMgc3RhcnRpbmcgd2l0aCBTLCBhdCBsZWFzdCA1IGxldHRlcnM='), b64d('U3R1ZGVudHMgd2hvc2UgbmFtZSBzdGFydHMgd2l0aCBgU2AgYW5kIGlzIGF0IGxlYXN0IDUgY2hhcmFjdGVycyBsb25nLiBVc2UgYExJS0VgIHdpdGggYF9gLgpPdXRwdXQ6IChJRCwgbmFtZSk='), b64d('UywgdGhlbiBmb3VyIGBfYCwgdGhlbiBgJWAu'), b64d(''), 'YF9gIG1hdGNoZXMgZXhhY3RseSBvbmUgY2hhcmFjdGVyLiBgJ1NfX19fJSdgID0gYW4gUywgdGhlbiBleGFjdGx5IGZvdXIgY2hhcmFjdGVycywgdGhlbiBhbnl0aGluZy4gU28gYXQgbGVhc3QgNSBjaGFyYWN0ZXJzIGluIHRvdGFsLiBTbm93ICg0IGxldHRlcnMpIGlzIGNvcnJlY3RseSBsZWZ0IG91dC4='),
  ('A6', true, 'c2VsZWN0IHVwcGVyKG5hbWUpIGFzIHVwcGVyX25hbWUsIGxlbmd0aChuYW1lKSBhcyBuYW1lX2xlbgpmcm9tIGluc3RydWN0b3IKd2hlcmUgbGVuZ3RoKG5hbWUpID4gNQpvcmRlciBieSBuYW1lX2xlbiBkZXNjLCB1cHBlcl9uYW1lOwo=', b64d('VXBwZXJjYXNlIG5hbWVzIGFuZCB0aGVpciBsZW5ndGhz'), b64d('Rm9yIGluc3RydWN0b3JzIHdob3NlIG5hbWUgaXMgbG9uZ2VyIHRoYW4gNSBjaGFyYWN0ZXJzOiB0aGUgbmFtZSBpbiB1cHBlcmNhc2UgYW5kIGl0cyBsZW5ndGguCk91dHB1dDogKHVwcGVyX25hbWUsIG5hbWVfbGVuKSDCtyAqKk9yZGVyOioqIG5hbWVfbGVuIGRlc2NlbmRpbmcsIHRoZW4gdXBwZXJfbmFtZSBhc2NlbmRpbmc='), b64d('YHVwcGVyKClgIGFuZCBgbGVuZ3RoKClgLiBJbiBgd2hlcmVgIHlvdSBtdXN0IHJlcGVhdCBgbGVuZ3RoKG5hbWUpYCwgYmVjYXVzZSB0aGUgYWxpYXMgZG9lc24ndCBleGlzdCB5ZXQgdGhlcmUu'), b64d(''), 'LSBUaGUgZnVuY3Rpb25zIGFyZSBgdXBwZXIoKWAgYW5kIGBsZW5ndGgoKWAuIFRoZXJlIGlzIG5vIGB1cHBlcmNhc2UoKWAuCi0gYHdoZXJlIGxlbmd0aChuYW1lKSA+IDVgOiB5b3UgbXVzdCByZXBlYXQgdGhlIGV4cHJlc3Npb24gaW4gYHdoZXJlYC4gVGhlIGFsaWFzIGBuYW1lX2xlbmAgZG9lcyBub3QgZXhpc3QgeWV0IHdoZW4gYHdoZXJlYCBydW5zIChvcmRlcjogZnJvbSDihpIgd2hlcmUg4oaSIGdyb3VwIGJ5IOKGkiBoYXZpbmcg4oaSIHNlbGVjdCDihpIgb3JkZXIgYnkpLgotIE1vemFydCBhbmQgQnJhbmR0IGJvdGggaGF2ZSA2IGxldHRlcnMsIHNvIHRoZSBzZWNvbmQgc29ydCBrZXkgZGVjaWRlcyB0aGVpciBvcmRlci4='),
  ('A7', false, 'KHNlbGVjdCBJRCBmcm9tIHRlYWNoZXMgd2hlcmUgc2VtZXN0ZXIgPSAnRmFsbCcgYW5kIHllYXIgPSAyMDI1KQp1bmlvbgooc2VsZWN0IElEIGZyb20gdGVhY2hlcyB3aGVyZSBzZW1lc3RlciA9ICdTcHJpbmcnIGFuZCB5ZWFyID0gMjAyNik7Cg==', b64d('VU5JT04='), b64d('SURzIG9mIGluc3RydWN0b3JzIHdobyB0YXVnaHQgYSBzZWN0aW9uIGluIEZhbGwgMjAyNSAqKm9yKiogaW4gU3ByaW5nIDIwMjYuIFVzZSBgVU5JT05gLgpPdXRwdXQ6IChJRCk='), b64d('VHdvIGNvbXBsZXRlIGBzZWxlY3QgLi4uIGZyb20gdGVhY2hlcyB3aGVyZSAuLi5gIGpvaW5lZCBieSBgdW5pb25gLg=='), b64d(''), 'RWFjaCBzaWRlIGlzIGEgY29tcGxldGUgYHNlbGVjdGAuIGB1bmlvbmAgc3RhY2tzIHRoZSByZXN1bHRzIGFuZCByZW1vdmVzIGR1cGxpY2F0ZXMgKFNyaW5pdmFzYW4gdGF1Z2h0IGluIGJvdGggdGVybXMgYnV0IGFwcGVhcnMgb25jZSkuIFVzZSBgdW5pb24gYWxsYCB0byBrZWVwIGR1cGxpY2F0ZXMuIEJvdGggc2lkZXMgbXVzdCByZXR1cm4gdGhlIHNhbWUgbnVtYmVyIG9mIGNvbHVtbnMgd2l0aCBjb21wYXRpYmxlIHR5cGVzLg=='),
  ('A8', false, 'KHNlbGVjdCBjb3Vyc2VfaWQgZnJvbSBzZWN0aW9uIHdoZXJlIHNlbWVzdGVyID0gJ0ZhbGwnIGFuZCB5ZWFyID0gMjAyNSkKaW50ZXJzZWN0CihzZWxlY3QgY291cnNlX2lkIGZyb20gc2VjdGlvbiB3aGVyZSBzZW1lc3RlciA9ICdGYWxsJyBhbmQgeWVhciA9IDIwMjYpOwo=', b64d('SU5URVJTRUNU'), b64d('Q291cnNlIElEcyBvZmZlcmVkIChoYXZlIGEgc2VjdGlvbikgaW4gKipib3RoKiogRmFsbCAyMDI1IGFuZCBGYWxsIDIwMjYuIFVzZSBgSU5URVJTRUNUYC4KT3V0cHV0OiAoY291cnNlX2lkKQ=='), b64d('VGhlIHRhYmxlIGlzIGBzZWN0aW9uYC4='), b64d(''), 'YGludGVyc2VjdGAga2VlcHMgcm93cyB0aGF0IGFwcGVhciBpbiBib3RoIHJlc3VsdHMuIE5vdGUgdGhhdCBgd2hlcmUgc2VtZXN0ZXIgPSAnRmFsbCcgYW5kIHllYXIgPSAyMDI1IGFuZCB5ZWFyID0gMjAyNmAgb24gb25lIHRhYmxlIHdvdWxkIHJldHVybiBub3RoaW5nOiBhIHNpbmdsZSByb3cgY2Fubm90IGhhdmUgdHdvIHllYXJzLiBUaGF0IGlzIHdoeSB5b3UgbmVlZCB0d28gcXVlcmllcy4='),
  ('A9', false, 'KHNlbGVjdCBjb3Vyc2VfaWQgZnJvbSBzZWN0aW9uIHdoZXJlIHNlbWVzdGVyID0gJ1NwcmluZycgYW5kIHllYXIgPSAyMDI2KQpleGNlcHQKKHNlbGVjdCBjb3Vyc2VfaWQgZnJvbSBzZWN0aW9uIHdoZXJlIHNlbWVzdGVyID0gJ0ZhbGwnIGFuZCB5ZWFyID0gMjAyNik7Cg==', b64d('RVhDRVBU'), b64d('Q291cnNlIElEcyBvZmZlcmVkIGluIFNwcmluZyAyMDI2IGJ1dCAqKm5vdCoqIGluIEZhbGwgMjAyNi4gVXNlIGBFWENFUFRgLgpPdXRwdXQ6IChjb3Vyc2VfaWQp'), b64d('Rmlyc3QgcXVlcnkgbWludXMgc2Vjb25kIHF1ZXJ5Lg=='), b64d(''), 'YGV4Y2VwdGAgPSBzZXQgZGlmZmVyZW5jZSAocmVsYXRpb25hbCBhbGdlYnJhIGDiiJJgKS4gUm93cyBmcm9tIHRoZSBmaXJzdCByZXN1bHQgdGhhdCBkbyBub3QgYXBwZWFyIGluIHRoZSBzZWNvbmQu'),
  ('A10', false, 'c2VsZWN0IG5hbWUKZnJvbSBpbnN0cnVjdG9yCndoZXJlIHNhbGFyeSBpcyBudWxsOwo=', b64d('VW5rbm93biBzYWxhcnk='), b64d('TmFtZXMgb2YgaW5zdHJ1Y3RvcnMgd2hvc2Ugc2FsYXJ5IGlzIHVua25vd24uCk91dHB1dDogKG5hbWUp'), b64d('YGlzIG51bGxg'), b64d(''), 'YHNhbGFyeSA9IG51bGxgIGlzIG5ldmVyIHRydWUuIEFueSBjb21wYXJpc29uIHdpdGggTlVMTCBnaXZlcyAqdW5rbm93biosIGFuZCBgd2hlcmVgIHRyZWF0cyB1bmtub3duIGFzIGZhbHNlLiBVc2UgYGlzIG51bGxgIC8gYGlzIG5vdCBudWxsYC4='),
  ('A11', false, 'c2VsZWN0IElELCBuYW1lCmZyb20gc3R1ZGVudAp3aGVyZSBkZXB0X25hbWUgPD4gJ0NvbXAuIFNjaS4nIG9yIGRlcHRfbmFtZSBpcyBudWxsOwo=', b64d('Tm90IGluIENvbXAuIFNjaS4gKGluY2x1ZGluZyBubyBkZXBhcnRtZW50KQ=='), b64d('U3R1ZGVudHMgd2hvIGFyZSAqKm5vdCoqIGluIHRoZSBgJ0NvbXAuIFNjaS4nYCBkZXBhcnRtZW50LCAqKmluY2x1ZGluZyoqIHN0dWRlbnRzIHdpdGggbm8gZGVwYXJ0bWVudCBhdCBhbGwuCk91dHB1dDogKElELCBuYW1lKQ=='), b64d('YG51bGwgPD4gJ0NvbXAuIFNjaS4nYCBpcyB1bmtub3duLCBub3QgdHJ1ZS4gWW91IG5lZWQgYSBzZWNvbmQgY29uZGl0aW9uIHdpdGggYG9yYC4='), b64d(''), 'VGhlIHRyYXA6IGZvciBPcnRpeiwgYGRlcHRfbmFtZSA8PiAnQ29tcC4gU2NpLidgIGlzIGBudWxsIDw+ICdDb21wLiBTY2kuJ2AgPSB1bmtub3duLCBzbyB0aGUgcm93IGlzIGRyb3BwZWQuIFRocmVlLXZhbHVlZCBsb2dpYzogYHVua25vd24gb3IgdHJ1ZSA9IHRydWVgLCBzbyBhZGRpbmcgYG9yIGRlcHRfbmFtZSBpcyBudWxsYCBicmluZ3MgT3J0aXogYmFjay4='),
  ('A12', true, 'c2VsZWN0IG5hbWUsCiAgICAgICBjYXNlIHdoZW4gc2FsYXJ5ID49IDgwMDAwIHRoZW4gJ2hpZ2gnCiAgICAgICAgICAgIHdoZW4gc2FsYXJ5IDwgODAwMDAgdGhlbiAnbG93JwogICAgICAgICAgICBlbHNlICd1bmtub3duJwogICAgICAgZW5kIGFzIHNhbGFyeV9sZXZlbApmcm9tIGluc3RydWN0b3IKb3JkZXIgYnkgbmFtZTsK', b64d('Q0FTRSBleHByZXNzaW9u'), b64d('Rm9yIGV2ZXJ5IGluc3RydWN0b3I6IG5hbWUgYW5kIHNhbGFyeSBsZXZlbDogYCdoaWdoJ2AgaWYgc2FsYXJ5IOKJpSA4MDAwMCwgYCdsb3cnYCBpZiBiZWxvdyA4MDAwMCwgYCd1bmtub3duJ2AgaWYgTlVMTC4gVXNlIGBDQVNFYC4KT3V0cHV0OiAobmFtZSwgc2FsYXJ5X2xldmVsKSDCtyAqKk9yZGVyOioqIG5hbWU='), b64d('YGNhc2Ugd2hlbiAuLi4gdGhlbiAuLi4gd2hlbiAuLi4gdGhlbiAuLi4gZWxzZSAuLi4gZW5kIGFzIHNhbGFyeV9sZXZlbGA='), b64d(''), 'YGNhc2Ugd2hlbiAuLi4gdGhlbiAuLi4gZWxzZSAuLi4gZW5kYCBpcyBhbiBleHByZXNzaW9uIHRoYXQgcHJvZHVjZXMgb25lIHZhbHVlIHBlciByb3cuIFRoZSBmaXJzdCBgd2hlbmAgdGhhdCBpcyB0cnVlIHdpbnMuIEZvciBQYXJrLCBib3RoIGBzYWxhcnkgPj0gODAwMDBgIGFuZCBgc2FsYXJ5IDwgODAwMDBgIGFyZSB1bmtub3duLCBzbyBuZWl0aGVyIGZpcmVzIGFuZCBgZWxzZWAgZ2l2ZXMgJ3Vua25vd24nLgoKV3JpdGluZyBgd2hlbiBzYWxhcnkgPSBudWxsIHRoZW4gJ3Vua25vd24nYCB3b3VsZCBuZXZlciBmaXJlIChzZWUgQTEwKS4='),
  ('B1', false, 'c2VsZWN0IGNvdW50KCopIGFzIG5fYWxsLAogICAgICAgY291bnQoc2FsYXJ5KSBhcyBuX3dpdGhfc2FsYXJ5LAogICAgICAgcm91bmQoYXZnKHNhbGFyeSksIDIpIGFzIGF2Z19zYWxhcnkKZnJvbSBpbnN0cnVjdG9yOwo=', b64d('Y291bnQoKikgdnMgY291bnQoY29sdW1uKQ=='), b64d('T25lIHJvdzogdGhlIG51bWJlciBvZiBpbnN0cnVjdG9ycywgdGhlIG51bWJlciBvZiBpbnN0cnVjdG9ycyB3aXRoIGEga25vd24gc2FsYXJ5LCBhbmQgdGhlIGF2ZXJhZ2Ugc2FsYXJ5IHJvdW5kZWQgdG8gMiBkZWNpbWFscy4KT3V0cHV0OiAobl9hbGwsIG5fd2l0aF9zYWxhcnksIGF2Z19zYWxhcnkp'), b64d('YGNvdW50KCopYCBjb3VudHMgcm93cywgYGNvdW50KHNhbGFyeSlgIGNvdW50cyBub24tTlVMTCB2YWx1ZXMu'), b64d(''), 'LSBgY291bnQoKilgIGNvdW50cyByb3dzOiAxMy4KLSBgY291bnQoc2FsYXJ5KWAgY291bnRzIG5vbi1OVUxMIHZhbHVlczogMTIgKFBhcmsgaGFzIG5vIHNhbGFyeSkuCi0gYGF2ZyhzYWxhcnkpYCBpZ25vcmVzIE5VTExzIHRvbzogaXQgaXMgc3VtIG9mIHRoZSAxMiBrbm93biBzYWxhcmllcyAvIDEyLCBub3QgLyAxMy4KQWxsIGFnZ3JlZ2F0ZXMgZXhjZXB0IGBjb3VudCgqKWAgaWdub3JlIE5VTExzLg=='),
  ('B2', true, 'c2VsZWN0IGRlcHRfbmFtZSwgY291bnQoKikgYXMgbnVtX2luc3RydWN0b3JzLCBtYXgoc2FsYXJ5KSBhcyBtYXhfc2FsYXJ5CmZyb20gaW5zdHJ1Y3Rvcgpncm91cCBieSBkZXB0X25hbWUKb3JkZXIgYnkgZGVwdF9uYW1lOwo=', b64d('R1JPVVAgQlk='), b64d('Rm9yIGVhY2ggZGVwYXJ0bWVudCB0aGF0IGhhcyBpbnN0cnVjdG9yczogdGhlIG51bWJlciBvZiBpbnN0cnVjdG9ycyBhbmQgdGhlIGhpZ2hlc3Qgc2FsYXJ5LgpPdXRwdXQ6IChkZXB0X25hbWUsIG51bV9pbnN0cnVjdG9ycywgbWF4X3NhbGFyeSkgwrcgKipPcmRlcjoqKiBkZXB0X25hbWU='), b64d('YGdyb3VwIGJ5IGRlcHRfbmFtZWAsIHdpdGggYGNvdW50KCopYCBhbmQgYG1heChzYWxhcnkpYC4='), b64d(''), 'YGdyb3VwIGJ5IGRlcHRfbmFtZWAgbWFrZXMgb25lIGdyb3VwIHBlciBkZXBhcnRtZW50LCBhbmQgdGhlIGFnZ3JlZ2F0ZXMgYXJlIGNvbXB1dGVkIHBlciBncm91cC4gRXZlcnkgY29sdW1uIGluIGBzZWxlY3RgIG11c3QgYmUgZWl0aGVyIGluIGBncm91cCBieWAgb3IgaW5zaWRlIGFuIGFnZ3JlZ2F0ZS4gV3JpdGluZyBgc2VsZWN0IGRlcHRfbmFtZSwgbmFtZSwgY291bnQoKikgLi4uIGdyb3VwIGJ5IGRlcHRfbmFtZWAgaXMgYW4gZXJyb3IsIGJlY2F1c2UgYSBncm91cCBoYXMgbWFueSBuYW1lcy4KCmBncm91cCBieWAgZG9lcyAqKm5vdCoqIHNvcnQuIFRoYXQgaXMgd2hhdCBgb3JkZXIgYnlgIGlzIGZvci4gVGhleSBhcmUgY29tcGxldGVseSBkaWZmZXJlbnQgY2xhdXNlcy4='),
  ('B3', false, 'c2VsZWN0IGRlcHRfbmFtZSwgcm91bmQoYXZnKHNhbGFyeSksIDIpIGFzIGF2Z19zYWxhcnkKZnJvbSBpbnN0cnVjdG9yCmdyb3VwIGJ5IGRlcHRfbmFtZQpoYXZpbmcgYXZnKHNhbGFyeSkgPiA3NTAwMDsK', b64d('SEFWSU5H'), b64d('RGVwYXJ0bWVudHMgd2hvc2UgYXZlcmFnZSBpbnN0cnVjdG9yIHNhbGFyeSBpcyBhYm92ZSA3NTAwMCwgd2l0aCB0aGF0IGF2ZXJhZ2Ugcm91bmRlZCB0byAyIGRlY2ltYWxzLgpPdXRwdXQ6IChkZXB0X25hbWUsIGF2Z19zYWxhcnkp'), b64d('RmlsdGVyaW5nIG9uIGFuIGFnZ3JlZ2F0ZSBuZWVkcyBgaGF2aW5nYCwgbm90IGB3aGVyZWAu'), b64d(''), 'YHdoZXJlYCBmaWx0ZXJzIHJvd3MgKmJlZm9yZSogZ3JvdXBpbmcsIHNvIGl0IGNhbm5vdCBzZWUgYGF2ZyguLi4pYC4gYGhhdmluZ2AgZmlsdGVycyBncm91cHMgKmFmdGVyKiB0aGUgYWdncmVnYXRlcyBleGlzdC4gUmVwZWF0IHRoZSBhZ2dyZWdhdGUgaW4gYGhhdmluZ2AsIG5vdCB0aGUgYWxpYXMu'),
  ('B4', false, 'c2VsZWN0IGNvdXJzZV9pZCwgY291bnQoZGlzdGluY3QgSUQpIGFzIG51bV9zdHVkZW50cwpmcm9tIHRha2VzCmdyb3VwIGJ5IGNvdXJzZV9pZApoYXZpbmcgY291bnQoZGlzdGluY3QgSUQpID49IDM7Cg==', b64d('Q09VTlQoRElTVElOQ1QgLi4uKQ=='), b64d('Rm9yIGVhY2ggY291cnNlOiB0aGUgbnVtYmVyIG9mICoqZGlzdGluY3QqKiBzdHVkZW50cyB3aG8gZXZlciB0b29rIGl0LiBPbmx5IGNvdXJzZXMgd2l0aCBhdCBsZWFzdCAzIGRpc3RpbmN0IHN0dWRlbnRzLgpPdXRwdXQ6IChjb3Vyc2VfaWQsIG51bV9zdHVkZW50cyk='), b64d('YGNvdW50KGRpc3RpbmN0IElEKWAuIExldnkgdG9vayBDUy0xMDEgdHdpY2Uu'), b64d(''), 'TGV2eSB0b29rIENTLTEwMSB0d2ljZSAoZmFpbGVkIGluIEZhbGwgMjAyNSwgcmV0b29rIGl0IGluIFNwcmluZyAyMDI2KS4gYGNvdW50KCopYCB3b3VsZCBjb3VudCBMZXZ5IHR3aWNlOyBgY291bnQoZGlzdGluY3QgSUQpYCBjb3VudHMgZWFjaCBzdHVkZW50IG9uY2Uu'),
  ('B5', true, 'c2VsZWN0IHllYXIsIHNlbWVzdGVyLCBjb3VudCgqKSBhcyBudW1fc2VjdGlvbnMKZnJvbSBzZWN0aW9uCmdyb3VwIGJ5IHllYXIsIHNlbWVzdGVyCm9yZGVyIGJ5IHllYXIsIHNlbWVzdGVyOwo=', b64d('R3JvdXAgYnkgdHdvIGNvbHVtbnM='), b64d('VGhlIG51bWJlciBvZiBzZWN0aW9ucyBvZmZlcmVkIGluIGVhY2ggdGVybS4KT3V0cHV0OiAoeWVhciwgc2VtZXN0ZXIsIG51bV9zZWN0aW9ucykgwrcgKipPcmRlcjoqKiB5ZWFyLCB0aGVuIHNlbWVzdGVy'), b64d('R3JvdXAgYnkgdHdvIGNvbHVtbnMu'), b64d(''), 'R3JvdXBpbmcgYnkgYCh5ZWFyLCBzZW1lc3RlcilgIG1ha2VzIG9uZSBncm91cCBwZXIgY29tYmluYXRpb24uIEFscGhhYmV0aWNhbGx5LCAnRmFsbCcgPCAnU3ByaW5nJyA8ICdTdW1tZXInLCB3aGljaCBpcyB3aGF0IGBvcmRlciBieSB5ZWFyLCBzZW1lc3RlcmAgZ2l2ZXMu'),
  ('B6', true, 'c2VsZWN0IElELAogICAgICAgc3VtKGNhc2Ugd2hlbiBncmFkZSBpcyBub3QgbnVsbCB0aGVuIDEgZWxzZSAwIGVuZCkgYXMgZG9uZSwKICAgICAgIHN1bShjYXNlIHdoZW4gZ3JhZGUgaXMgbnVsbCB0aGVuIDEgZWxzZSAwIGVuZCkgYXMgaW5fcHJvZ3Jlc3MKZnJvbSB0YWtlcwpncm91cCBieSBJRApvcmRlciBieSBJRDsK', b64d('Q29uZGl0aW9uYWwgYWdncmVnYXRpb24gKFR5cGUgOSk='), b64d('Rm9yIGVhY2ggc3R1ZGVudCB3aXRoIGF0IGxlYXN0IG9uZSBgdGFrZXNgIHJvdzogaG93IG1hbnkgY291cnNlcyBhcmUgZmluaXNoZWQgKG5vbi1OVUxMIGdyYWRlKSBhbmQgaG93IG1hbnkgYXJlIGluIHByb2dyZXNzIChOVUxMIGdyYWRlKS4gVXNlIGBTVU0oQ0FTRSAuLi4pYC4KT3V0cHV0OiAoSUQsIGRvbmUsIGluX3Byb2dyZXNzKSDCtyAqKk9yZGVyOioqIElE'), b64d('YHN1bShjYXNlIHdoZW4gZ3JhZGUgaXMgbm90IG51bGwgdGhlbiAxIGVsc2UgMCBlbmQpYA=='), b64d(''), 'SW5zaWRlIGVhY2ggc3R1ZGVudCdzIGdyb3VwLCBldmVyeSByb3cgYmVjb21lcyAxIG9yIDAgYW5kIGBzdW1gIGFkZHMgdGhlbSB1cC4gRXF1aXZhbGVudCBzaG9ydGN1dDogYGNvdW50KGdyYWRlKWAgY291bnRzIG5vbi1OVUxMIGdyYWRlcywgYW5kIGBjb3VudCgqKSAtIGNvdW50KGdyYWRlKWAgY291bnRzIHRoZSBOVUxMIG9uZXMu'),
  ('B7', false, 'c2VsZWN0IGkubmFtZSwgY291bnQoZGlzdGluY3QgdC5jb3Vyc2VfaWQpIGFzIG51bV9jb3Vyc2VzCmZyb20gaW5zdHJ1Y3RvciBpCmpvaW4gdGVhY2hlcyB0IG9uIGkuSUQgPSB0LklECmdyb3VwIGJ5IGkuSUQsIGkubmFtZQpoYXZpbmcgY291bnQoZGlzdGluY3QgdC5jb3Vyc2VfaWQpID49IDI7Cg==', b64d('Sm9pbiArIGdyb3VwIGJ5ICsgaGF2aW5n'), b64d('SW5zdHJ1Y3RvcnMgd2hvIGhhdmUgdGF1Z2h0IGF0IGxlYXN0IDIgKipkaWZmZXJlbnQqKiBjb3Vyc2VzIChhbnkgdGVybXMpLCB3aXRoIHRoYXQgbnVtYmVyLgpPdXRwdXQ6IChuYW1lLCBudW1fY291cnNlcyk='), b64d('Sm9pbiBgaW5zdHJ1Y3RvcmAgd2l0aCBgdGVhY2hlc2AsIGdyb3VwIGJ5IHRoZSBpbnN0cnVjdG9yLCBgaGF2aW5nIGNvdW50KGRpc3RpbmN0IC4uLilgLg=='), b64d(''), 'R3JvdXAgYnkgYGkuSUQsIGkubmFtZWAsIG5vdCBqdXN0IGBpLm5hbWVgLiBUd28gaW5zdHJ1Y3RvcnMgY291bGQgc2hhcmUgYSBuYW1lLCBhbmQgdGhlIElEIGtlZXBzIHRoZW0gYXBhcnQuIFNpbmNlIGBuYW1lYCBpcyBpbiBgc2VsZWN0YCwgaXQgbXVzdCBhbHNvIGJlIGluIGBncm91cCBieWAu'),
  ('C1', false, 'c2VsZWN0IGRpc3RpbmN0IGkubmFtZSwgdC5jb3Vyc2VfaWQKZnJvbSBpbnN0cnVjdG9yIGkKam9pbiB0ZWFjaGVzIHQgb24gaS5JRCA9IHQuSUQ7Cg==', b64d('QmFzaWMgam9pbg=='), b64d('RWFjaCBpbnN0cnVjdG9yJ3MgbmFtZSB3aXRoIHRoZSBjb3Vyc2VfaWQgb2YgZXZlcnkgY291cnNlIHRoZXkgaGF2ZSB0YXVnaHQgKGFueSB0ZXJtKSwgd2l0aG91dCBkdXBsaWNhdGVzLgpPdXRwdXQ6IChuYW1lLCBjb3Vyc2VfaWQp'), b64d('YGpvaW4gdGVhY2hlcyBvbiBpbnN0cnVjdG9yLklEID0gdGVhY2hlcy5JRGA='), b64d(''), 'YGpvaW4gLi4uIG9uYCBwYWlycyBlYWNoIGluc3RydWN0b3Igd2l0aCBlYWNoIG9mIHRoZWlyIHRlYWNoZXMgcm93cy4gVGhlIG9sZCBjb21tYSBmb3JtIGBmcm9tIGluc3RydWN0b3IgaSwgdGVhY2hlcyB0IHdoZXJlIGkuSUQgPSB0LklEYCBpcyB0aGUgc2FtZSB0aGluZyAoQ2FydGVzaWFuIHByb2R1Y3QgKyBzZWxlY3Rpb24pLiBGb3JnZXR0aW5nIHRoZSBjb25kaXRpb24gZ2l2ZXMgdGhlIGZ1bGwgQ2FydGVzaWFuIHByb2R1Y3QgKDEzIMOXIDIwIHJvd3MpLg=='),
  ('C2', true, 'c2VsZWN0IHQuY291cnNlX2lkLCB0LnNlY19pZCwgYy50aXRsZSwgaS5uYW1lIGFzIGluc3RydWN0b3IKZnJvbSB0ZWFjaGVzIHQKam9pbiBjb3Vyc2UgYyBvbiBjLmNvdXJzZV9pZCA9IHQuY291cnNlX2lkCmpvaW4gaW5zdHJ1Y3RvciBpIG9uIGkuSUQgPSB0LklECndoZXJlIHQuc2VtZXN0ZXIgPSAnU3ByaW5nJyBhbmQgdC55ZWFyID0gMjAyNgpvcmRlciBieSB0LmNvdXJzZV9pZCwgdC5zZWNfaWQ7Cg==', b64d('VGhyZWUtdGFibGUgam9pbg=='), b64d('RXZlcnkgc2VjdGlvbiB0YXVnaHQgaW4gU3ByaW5nIDIwMjY6IGNvdXJzZSwgc2VjdGlvbiwgY291cnNlIHRpdGxlIGFuZCB0aGUgaW5zdHJ1Y3RvcidzIG5hbWUuCk91dHB1dDogKGNvdXJzZV9pZCwgc2VjX2lkLCB0aXRsZSwgaW5zdHJ1Y3RvcikgwrcgKipPcmRlcjoqKiBjb3Vyc2VfaWQsIHRoZW4gc2VjX2lk'), b64d('dGVhY2hlcyDihpIgY291cnNlICh0aXRsZSkgYW5kIHRlYWNoZXMg4oaSIGluc3RydWN0b3IgKG5hbWUpLg=='), b64d(''), 'QSBwYXRoIHRocm91Z2ggdGhlIHNjaGVtYTogdGVhY2hlcyDihpIgY291cnNlIChmb3IgdGhlIHRpdGxlKSBhbmQgdGVhY2hlcyDihpIgaW5zdHJ1Y3RvciAoZm9yIHRoZSBuYW1lKS4gRmlsdGVyIHRoZSB0ZXJtIG9uIHRoZSB0ZWFjaGVzIGNvbHVtbnMu'),
  ('C3', false, 'c2VsZWN0IGRpc3RpbmN0IHMubmFtZSwgYy50aXRsZQpmcm9tIHN0dWRlbnQgcwpqb2luIHRha2VzIHQgb24gcy5JRCA9IHQuSUQKam9pbiBjb3Vyc2UgYyBvbiB0LmNvdXJzZV9pZCA9IGMuY291cnNlX2lkOwo=', b64d('VGhlIG5hdHVyYWwtam9pbiB0cmFw'), b64d('TmFtZXMgb2Ygc3R1ZGVudHMgd2l0aCB0aGUgdGl0bGVzIG9mIGNvdXJzZXMgdGhleSBoYXZlIHRha2VuLCB3aXRob3V0IGR1cGxpY2F0ZXMuIChUcnkgYG5hdHVyYWwgam9pbmAgZmlyc3QgYW5kIGNvbXBhcmUgdGhlIHJvdyBjb3VudHMuKQpPdXRwdXQ6IChuYW1lLCB0aXRsZSk='), b64d('c3R1ZGVudCBhbmQgY291cnNlIGJvdGggaGF2ZSBgZGVwdF9uYW1lYC4gQSBuYXR1cmFsIGpvaW4gd291bGQgY29tcGFyZSBpdCB0b28u'), b64d(''), 'YHN0dWRlbnQgbmF0dXJhbCBqb2luIHRha2VzIG5hdHVyYWwgam9pbiBjb3Vyc2VgIGlzIHdyb25nLiBzdHVkZW50IGFuZCBjb3Vyc2UgYm90aCBoYXZlIGEgYGRlcHRfbmFtZWAgY29sdW1uLCBzbyB0aGUgc2Vjb25kIG5hdHVyYWwgam9pbiBhbHNvIHJlcXVpcmVzIGBzdHVkZW50LmRlcHRfbmFtZSA9IGNvdXJzZS5kZXB0X25hbWVgLiBJdCBzaWxlbnRseSBkcm9wcyBldmVyeSBzdHVkZW50IHdobyB0b29rIGEgY291cnNlIG91dHNpZGUgdGhlaXIgb3duIGRlcGFydG1lbnQgKEJyYW5kdCBmcm9tIEhpc3RvcnkgdGFraW5nIENTLTEwMSwgZm9yIGV4YW1wbGUpLiBUaGF0IGlzIGV4YWN0bHkgdGhlIGxlY3R1cmUgc2xpZGUgIkRhbmdlciBpbiBuYXR1cmFsIGpvaW4iLiBVc2UgZXhwbGljaXQgYG9uYCBjb25kaXRpb25zIChvciBgam9pbiBjb3Vyc2UgdXNpbmcgKGNvdXJzZV9pZClgKS4='),
  ('C4', true, 'c2VsZWN0IGEubmFtZSBhcyBuYW1lMSwgYi5uYW1lIGFzIG5hbWUyLCBhLmRlcHRfbmFtZQpmcm9tIGluc3RydWN0b3IgYQpqb2luIGluc3RydWN0b3IgYiBvbiBhLmRlcHRfbmFtZSA9IGIuZGVwdF9uYW1lIGFuZCBhLm5hbWUgPCBiLm5hbWUKb3JkZXIgYnkgbmFtZTEsIG5hbWUyOwo=', b64d('U2VsZi1qb2luIChUeXBlIDcp'), b64d('UGFpcnMgb2YgaW5zdHJ1Y3RvcnMgaW4gdGhlIHNhbWUgZGVwYXJ0bWVudCwgZWFjaCBwYWlyIG9uY2UgKGZpcnN0IG5hbWUgYWxwaGFiZXRpY2FsbHkgc21hbGxlcikuCk91dHB1dDogKG5hbWUxLCBuYW1lMiwgZGVwdF9uYW1lKSDCtyAqKk9yZGVyOioqIG5hbWUxLCB0aGVuIG5hbWUy'), b64d('YGluc3RydWN0b3IgYSBqb2luIGluc3RydWN0b3IgYiBvbiBhLmRlcHRfbmFtZSA9IGIuZGVwdF9uYW1lIGFuZCBhLm5hbWUgPCBiLm5hbWVg'), b64d(''), 'VHdvIGNvcGllcyBvZiB0aGUgc2FtZSB0YWJsZSBuZWVkIHR3byBhbGlhc2VzIChgYWAsIGBiYCk6IHRoZSBsZWN0dXJlJ3MgKnJlbmFtZSogb3BlcmF0b3Igz4EuIGBhLm5hbWUgPCBiLm5hbWVgIGRvZXMgdHdvIGpvYnMuIEl0IHJlbW92ZXMgcGFpcmluZyBzb21lb25lIHdpdGggdGhlbXNlbHZlcywgYW5kIGl0IGtlZXBzIG9ubHkgb25lIG9mIChLYXR6LCBCcmFuZHQpIC8gKEJyYW5kdCwgS2F0eiku'),
  ('C5', false, 'c2VsZWN0IHAxLmNvdXJzZV9pZCwgcDEucHJlcmVxX2lkLCBwMi5wcmVyZXFfaWQgYXMgcHJlcmVxX29mX3ByZXJlcQpmcm9tIHByZXJlcSBwMQpqb2luIHByZXJlcSBwMiBvbiBwMS5wcmVyZXFfaWQgPSBwMi5jb3Vyc2VfaWQ7Cg==', b64d('UHJlcmVxdWlzaXRlIG9mIGEgcHJlcmVxdWlzaXRl'), b64d('VHdvLXN0ZXAgcHJlcmVxdWlzaXRlIGNoYWluczogYSBjb3Vyc2UsIG9uZSBvZiBpdHMgcHJlcmVxdWlzaXRlcywgYW5kIGEgcHJlcmVxdWlzaXRlICoqb2YgdGhhdCBwcmVyZXF1aXNpdGUqKi4KT3V0cHV0OiAoY291cnNlX2lkLCBwcmVyZXFfaWQsIHByZXJlcV9vZl9wcmVyZXEp'), b64d('Sm9pbiBgcHJlcmVxYCB0byBpdHNlbGY6IHRoZSBmaXJzdCByb3cncyBgcHJlcmVxX2lkYCBpcyB0aGUgc2Vjb25kIHJvdydzIGBjb3Vyc2VfaWRgLg=='), b64d(''), 'U2FtZSBpZGVhIGFzIHRoZSAiZ3JhbmRwYXJlbnRzIG9mIFRvbSIgc2xpZGUuIEpvaW4gcHJlcmVxIHRvIGl0c2VsZiB3aGVyZSB0aGUgZmlyc3Qgcm93J3MgYHByZXJlcV9pZGAgaXMgdGhlIHNlY29uZCByb3cncyBgY291cnNlX2lkYC4='),
  ('C6', false, 'c2VsZWN0IGEuSUQgYXMgaWQxLCBiLklEIGFzIGlkMiwgYS5jb3Vyc2VfaWQKZnJvbSB0YWtlcyBhCmpvaW4gdGFrZXMgYiBvbiBhLmNvdXJzZV9pZCA9IGIuY291cnNlX2lkCiAgICAgICAgICAgIGFuZCBhLnNlY19pZCA9IGIuc2VjX2lkCiAgICAgICAgICAgIGFuZCBhLnNlbWVzdGVyID0gYi5zZW1lc3RlcgogICAgICAgICAgICBhbmQgYS55ZWFyID0gYi55ZWFyCiAgICAgICAgICAgIGFuZCBhLklEIDwgYi5JRAp3aGVyZSBhLnNlbWVzdGVyID0gJ0ZhbGwnIGFuZCBhLnllYXIgPSAyMDI2Owo=', b64d('Q2xhc3NtYXRlcyAoc2VsZi1qb2luIG9uIHRha2VzKQ=='), b64d('UGFpcnMgb2Ygc3R1ZGVudHMgaW4gdGhlICoqc2FtZSBzZWN0aW9uKiogaW4gRmFsbCAyMDI2LCBlYWNoIHBhaXIgb25jZSAoYGlkMSA8IGlkMmApLgpPdXRwdXQ6IChpZDEsIGlkMiwgY291cnNlX2lkKQ=='), b64d('QSBzZWN0aW9uID0gY291cnNlX2lkICsgc2VjX2lkICsgc2VtZXN0ZXIgKyB5ZWFyLiBBbGwgZm91ciBtdXN0IG1hdGNoLg=='), b64d(''), 'QSBzZWN0aW9uIGlzIGlkZW50aWZpZWQgYnkgYWxsIGZvdXIgY29sdW1ucyAoY291cnNlX2lkLCBzZWNfaWQsIHNlbWVzdGVyLCB5ZWFyKSwgc28gYWxsIGZvdXIgbXVzdCBtYXRjaC4gTWF0Y2hpbmcgb25seSBgY291cnNlX2lkYCB3b3VsZCBwYWlyIHN0dWRlbnRzIGZyb20gZGlmZmVyZW50IHRlcm1zLg=='),
  ('D1', false, 'c2VsZWN0IGRpc3RpbmN0IHMubmFtZQpmcm9tIHN0dWRlbnQgcwpqb2luIHRha2VzIHQgb24gcy5JRCA9IHQuSUQKd2hlcmUgKHQuY291cnNlX2lkLCB0LnNlY19pZCwgdC5zZW1lc3RlciwgdC55ZWFyKSBpbgogICAgICAoc2VsZWN0IHRlLmNvdXJzZV9pZCwgdGUuc2VjX2lkLCB0ZS5zZW1lc3RlciwgdGUueWVhcgogICAgICAgZnJvbSB0ZWFjaGVzIHRlCiAgICAgICBqb2luIGluc3RydWN0b3IgaSBvbiB0ZS5JRCA9IGkuSUQKICAgICAgIHdoZXJlIGkubmFtZSA9ICdFaW5zdGVpbicpOwo=', b64d('SU4gd2l0aCBhIHN1YnF1ZXJ5'), b64d('TmFtZXMgb2Ygc3R1ZGVudHMgd2hvIHRvb2sgKGFueSB0ZXJtKSBhICoqc2VjdGlvbioqIHRhdWdodCBieSBFaW5zdGVpbiwgd2l0aG91dCBkdXBsaWNhdGVzLiBVc2UgYElOYCB3aXRoIGEgc3VicXVlcnkuCk91dHB1dDogKG5hbWUp'), b64d('YChjb3Vyc2VfaWQsIHNlY19pZCwgc2VtZXN0ZXIsIHllYXIpIGluIChzZWxlY3QgLi4uIGZyb20gdGVhY2hlcyBqb2luIGluc3RydWN0b3IgLi4uIHdoZXJlIG5hbWUgPSAnRWluc3RlaW4nKWA='), b64d(''), 'Um93IGNvbnN0cnVjdG9ycyBgKGEsIGIsIGMsIGQpIGluIChzZWxlY3QgdywgeCwgeSwgeiAuLi4pYCBjb21wYXJlIHNldmVyYWwgY29sdW1ucyBhdCBvbmNlLiBZb3UgbXVzdCBtYXRjaCB0aGUgKnNlY3Rpb24qLCBub3QganVzdCB0aGUgY291cnNlLiBPdGhlcndpc2UgYSBzdHVkZW50IHdobyB0b29rIFBIWS0xMDEgZnJvbSBzb21lb25lIGVsc2Ugd291bGQgY291bnQuIEEgcGxhaW4gNC10YWJsZSBqb2luIHdpdGggYGRpc3RpbmN0YCBhbHNvIHdvcmtzLg=='),
  ('D2', false, 'c2VsZWN0IElELCBuYW1lCmZyb20gc3R1ZGVudAp3aGVyZSBJRCBub3QgaW4gKHNlbGVjdCBJRCBmcm9tIHRha2VzKTsK', b64d('TmV2ZXIgdG9vayBhIGNvdXJzZQ=='), b64d('U3R1ZGVudHMgd2hvIGhhdmUgbmV2ZXIgdGFrZW4gYW55IGNvdXJzZS4KT3V0cHV0OiAoSUQsIG5hbWUp'), b64d('YElEIG5vdCBpbiAoc2VsZWN0IElEIGZyb20gdGFrZXMpYCBvciBgbm90IGV4aXN0c2Au'), b64d(''), 'YG5vdCBpbmAgd29ya3MgaGVyZSBiZWNhdXNlIGB0YWtlcy5JRGAgY2FuIG5ldmVyIGJlIE5VTEwgKGl0IGlzIHBhcnQgb2YgdGhlIHByaW1hcnkga2V5KS4gSWYgdGhlIHN1YnF1ZXJ5IGNvdWxkIHJldHVybiBhIE5VTEwsIGB4IG5vdCBpbiAoLi4uLCBudWxsKWAgaXMgbmV2ZXIgdHJ1ZSBhbmQgeW91IGdldCB6ZXJvIHJvd3MuIGBub3QgZXhpc3RzYCBoYXMgbm8gc3VjaCBwcm9ibGVtOgpgYGBzcWwKc2VsZWN0IHMuSUQsIHMubmFtZSBmcm9tIHN0dWRlbnQgcwp3aGVyZSBub3QgZXhpc3RzIChzZWxlY3QgMSBmcm9tIHRha2VzIHQgd2hlcmUgdC5JRCA9IHMuSUQpOwpgYGA='),
  ('D3', false, 'c2VsZWN0IG5hbWUKZnJvbSBpbnN0cnVjdG9yCndoZXJlIHNhbGFyeSA+IGFsbCAoc2VsZWN0IHNhbGFyeSBmcm9tIGluc3RydWN0b3Igd2hlcmUgZGVwdF9uYW1lID0gJ0ZpbmFuY2UnKTsK', b64d('PiBBTEw='), b64d('TmFtZXMgb2YgaW5zdHJ1Y3RvcnMgd2hvIGVhcm4gbW9yZSB0aGFuICoqZXZlcnkqKiBpbnN0cnVjdG9yIGluIEZpbmFuY2UuIFVzZSBgPiBBTExgLgpPdXRwdXQ6IChuYW1lKQ=='), b64d('YHNhbGFyeSA+IGFsbCAoc2VsZWN0IHNhbGFyeSBmcm9tIGluc3RydWN0b3Igd2hlcmUgZGVwdF9uYW1lID0gJ0ZpbmFuY2UnKWA='), b64d(''), 'YD4gYWxsIChzdWJxdWVyeSlgID0gZ3JlYXRlciB0aGFuIGV2ZXJ5IHZhbHVlIHJldHVybmVkLiBGaW5hbmNlIGVhcm5zIDkwMDAwIGFuZCA4MDAwMCwgc28geW91IG5lZWQgPiA5MDAwMC4gVHJ5IHRoZSBzYW1lIHdpdGggRWxlYy4gRW5nLiBpbnN0ZWFkIG9mIEZpbmFuY2UuIFBhcmsncyBOVUxMIHNhbGFyeSBtYWtlcyBgeCA+IGFsbCAoODAwMDAsIG51bGwpYCB1bmtub3duIGZvciBldmVyeW9uZSwgYW5kIHlvdSBnZXQgemVybyByb3dzLiBOVUxMcyBwb2lzb24gYGFsbGAu'),
  ('D4', false, 'c2VsZWN0IG5hbWUKZnJvbSBpbnN0cnVjdG9yCndoZXJlIHNhbGFyeSA+IHNvbWUgKHNlbGVjdCBzYWxhcnkgZnJvbSBpbnN0cnVjdG9yIHdoZXJlIGRlcHRfbmFtZSA9ICdIaXN0b3J5Jyk7Cg==', b64d('PiBTT01F'), b64d('TmFtZXMgb2YgaW5zdHJ1Y3RvcnMgd2hvIGVhcm4gbW9yZSB0aGFuICoqYXQgbGVhc3Qgb25lKiogaW5zdHJ1Y3RvciBpbiBIaXN0b3J5LiBVc2UgYD4gU09NRWAuCk91dHB1dDogKG5hbWUp'), b64d('U2FtZSBzaGFwZSBhcyBEMyB3aXRoIGBzb21lYC4='), b64d(''), 'YD4gc29tZWAgPSBncmVhdGVyIHRoYW4gYXQgbGVhc3Qgb25lIHZhbHVlLiBIaXN0b3J5IHBheXMgNjAwMDAgYW5kIDYyMDAwLCBzbyBhbnlvbmUgYWJvdmUgNjAwMDAgcXVhbGlmaWVzLCBpbmNsdWRpbmcgQ2FsaWZpZXJpIGZyb20gSGlzdG9yeSBpdHNlbGYgKDYyMDAwID4gNjAwMDApLiBFbCBTYWlkICg2MDAwMCkgZG9lcyBub3Q6IDYwMDAwIGlzIG5vdCA+IDYwMDAwLg=='),
  ('D5', false, 'c2VsZWN0IGRpc3RpbmN0IGkubmFtZQpmcm9tIGluc3RydWN0b3IgaQpqb2luIHRlYWNoZXMgdCBvbiBpLklEID0gdC5JRAp3aGVyZSBub3QgZXhpc3RzIChzZWxlY3QgMQogICAgICAgICAgICAgICAgICBmcm9tIHRha2VzIGsKICAgICAgICAgICAgICAgICAgd2hlcmUgay5jb3Vyc2VfaWQgPSB0LmNvdXJzZV9pZAogICAgICAgICAgICAgICAgICAgIGFuZCBrLnNlY19pZCA9IHQuc2VjX2lkCiAgICAgICAgICAgICAgICAgICAgYW5kIGsuc2VtZXN0ZXIgPSB0LnNlbWVzdGVyCiAgICAgICAgICAgICAgICAgICAgYW5kIGsueWVhciA9IHQueWVhcik7Cg==', b64d('Q29ycmVsYXRlZCBOT1QgRVhJU1RTIChUeXBlIDUp'), b64d('TmFtZXMgb2YgaW5zdHJ1Y3RvcnMgKG5vIGR1cGxpY2F0ZXMpIHdobyBoYXZlIHRhdWdodCBhdCBsZWFzdCBvbmUgc2VjdGlvbiB3aXRoICoqbm8gc3R1ZGVudHMgYXQgYWxsKiouIFVzZSBgTk9UIEVYSVNUU2AuCk91dHB1dDogKG5hbWUp'), b64d('Q29ycmVsYXRlZDogaW5zaWRlIHRoZSBzdWJxdWVyeSwgbWF0Y2ggdGFrZXMgcm93cyB0byB0aGUgb3V0ZXIgdGVhY2hlcyByb3cgb24gYWxsIGZvdXIgc2VjdGlvbiBjb2x1bW5zLg=='), b64d(''), 'VGhlIHN1YnF1ZXJ5IG1lbnRpb25zIGB0YCBmcm9tIHRoZSBvdXRlciBxdWVyeSwgc28gaXQgaXMgKmNvcnJlbGF0ZWQqOiBpdCBydW5zIG9uY2UgcGVyIHRlYWNoZXMgcm93LiAiRm9yIHRoaXMgc2VjdGlvbiwgaXMgdGhlcmUgYW55IHRha2VzIHJvdz8iIGBub3QgZXhpc3RzYCBpcyB0cnVlIHdoZW4gdGhlIHN1YnF1ZXJ5IHJldHVybnMgbm90aGluZy4gVGhlIGBzZWxlY3QgMWAgaW5zaWRlIGRvZXMgbm90IG1hdHRlcjsgYGV4aXN0c2Agb25seSBjaGVja3Mgd2hldGhlciBhbnkgcm93IGNvbWVzIGJhY2su'),
  ('D6', false, 'c2VsZWN0IG5hbWUKZnJvbSBpbnN0cnVjdG9yIGkKd2hlcmUgZXhpc3RzIChzZWxlY3QgMSBmcm9tIGFkdmlzb3IgYSB3aGVyZSBhLmlfSUQgPSBpLklEKTsK', b64d('RVhJU1RT'), b64d('TmFtZXMgb2YgaW5zdHJ1Y3RvcnMgd2hvIGFkdmlzZSBhdCBsZWFzdCBvbmUgc3R1ZGVudC4gVXNlIGBFWElTVFNgLgpPdXRwdXQ6IChuYW1lKQ=='), b64d('YHdoZXJlIGV4aXN0cyAoc2VsZWN0IDEgZnJvbSBhZHZpc29yIGEgd2hlcmUgYS5pX0lEID0gaS5JRClg'), b64d(''), 'RWFjaCBpbnN0cnVjdG9yIGlzIGNoZWNrZWQgb25jZSwgc28gbm9ib2R5IGFwcGVhcnMgdHdpY2UuIENvbXBhcmUgd2l0aCBhIGpvaW4gKGBpbnN0cnVjdG9yIGpvaW4gYWR2aXNvcmApLCB3aGljaCBnaXZlcyBvbmUgcm93IHBlciBhZHZpc2VkIHN0dWRlbnQgYW5kIG5lZWRzIGBkaXN0aW5jdGAu'),
  ('D7', false, 'c2VsZWN0IHMuSUQsIHMubmFtZQpmcm9tIHN0dWRlbnQgcwp3aGVyZSBub3QgZXhpc3RzICgKICAgICAgICAoc2VsZWN0IHQuY291cnNlX2lkCiAgICAgICAgIGZyb20gdGVhY2hlcyB0IGpvaW4gaW5zdHJ1Y3RvciBpIG9uIHQuSUQgPSBpLklECiAgICAgICAgIHdoZXJlIGkubmFtZSA9ICdLYXR6JykKICAgICAgICBleGNlcHQKICAgICAgICAoc2VsZWN0IGsuY291cnNlX2lkIGZyb20gdGFrZXMgayB3aGVyZSBrLklEID0gcy5JRCkpOwo=', b64d('IkV2ZXJ5IjogZGl2aXNpb24gd2l0aCBOT1QgRVhJU1RTICsgRVhDRVBU'), b64d('U3R1ZGVudHMgd2hvIGhhdmUgdGFrZW4gKipldmVyeSoqIGNvdXJzZSB0aGF0IEthdHogaGFzIGV2ZXIgdGF1Z2h0LiBVc2UgYE5PVCBFWElTVFMgKC4uLiBFWENFUFQgLi4uKWAuCk91dHB1dDogKElELCBuYW1lKQ=='), b64d('KEthdHoncyBjb3Vyc2VzKSBFWENFUFQgKHRoaXMgc3R1ZGVudCdzIGNvdXJzZXMpIG11c3QgYmUgZW1wdHku'), b64d(''), 'VGhlIGxlY3R1cmUgcGF0dGVybiBmb3IgInN0dWRlbnRzIHdobyB0b29rICoqYWxsKiogWCI6IChzZXQgb2YgWCkg4oiSIChjb3Vyc2VzIHRoaXMgc3R1ZGVudCB0b29rKSBtdXN0IGJlIGVtcHR5LgotIElubmVyIGxlZnQgc2lkZTogZXZlcnkgY291cnNlIEthdHogdGF1Z2h0ID0ge0NTLTEwMSwgQ1MtMzE5fS4KLSBJbm5lciByaWdodCBzaWRlOiBldmVyeSBjb3Vyc2UgKnRoaXMqIHN0dWRlbnQgdG9vayAoY29ycmVsYXRlZCBvbiBgcy5JRGApLgotIGBleGNlcHRgIGxlYXZlcyB0aGUgS2F0eiBjb3Vyc2VzIHRoZSBzdHVkZW50IGlzIG1pc3Npbmc7IGBub3QgZXhpc3RzYCBrZWVwcyB0aGUgc3R1ZGVudCBvbmx5IGlmIG5vdGhpbmcgaXMgbWlzc2luZy4KUmVsYXRpb25hbCBhbGdlYnJhOiDPgDxzdWI+SUQsIGNvdXJzZV9pZDwvc3ViPih0YWtlcykgw7cgz4A8c3ViPmNvdXJzZV9pZDwvc3ViPijPgzxzdWI+bmFtZT0nS2F0eic8L3N1Yj4oaW5zdHJ1Y3RvciDii4ggdGVhY2hlcykpLg=='),
  ('D8', true, 'c2VsZWN0IGkuZGVwdF9uYW1lLCBpLm5hbWUsIGkuc2FsYXJ5CmZyb20gaW5zdHJ1Y3RvciBpCndoZXJlIGkuc2FsYXJ5ID0gKHNlbGVjdCBtYXgoaTIuc2FsYXJ5KQogICAgICAgICAgICAgICAgICBmcm9tIGluc3RydWN0b3IgaTIKICAgICAgICAgICAgICAgICAgd2hlcmUgaTIuZGVwdF9uYW1lID0gaS5kZXB0X25hbWUpCm9yZGVyIGJ5IGkuZGVwdF9uYW1lLCBpLm5hbWU7Cg==', b64d('Q29ycmVsYXRlZCBzY2FsYXIgc3VicXVlcnkgKFR5cGUgMyk='), b64d('SW4gZWFjaCBkZXBhcnRtZW50LCB0aGUgaW5zdHJ1Y3RvcihzKSB3aXRoIHRoZSBoaWdoZXN0IHNhbGFyeS4gVXNlIGEgY29ycmVsYXRlZCBzdWJxdWVyeS4KT3V0cHV0OiAoZGVwdF9uYW1lLCBuYW1lLCBzYWxhcnkpIMK3ICoqT3JkZXI6KiogZGVwdF9uYW1lLCB0aGVuIG5hbWU='), b64d('YHNhbGFyeSA9IChzZWxlY3QgbWF4KGkyLnNhbGFyeSkgZnJvbSBpbnN0cnVjdG9yIGkyIHdoZXJlIGkyLmRlcHRfbmFtZSA9IGkuZGVwdF9uYW1lKWA='), b64d(''), 'Rm9yIGVhY2ggb3V0ZXIgcm93IGBpYCwgdGhlIHN1YnF1ZXJ5IGNvbXB1dGVzIHRoZSBtYXggc2FsYXJ5IG9mICp0aGF0IHJvdydzKiBkZXBhcnRtZW50IChgaTIuZGVwdF9uYW1lID0gaS5kZXB0X25hbWVgKS4gVGllcyB3b3VsZCBhbGwgYmUgcmV0dXJuZWQuIFBhcmsgKE5VTEwgc2FsYXJ5KSBuZXZlciBtYXRjaGVzLCBiZWNhdXNlIGBudWxsID0gODAwMDBgIGlzIHVua25vd24u'),
  ('D9', false, 'c2VsZWN0IGRlcHRfbmFtZQpmcm9tIGluc3RydWN0b3IKZ3JvdXAgYnkgZGVwdF9uYW1lCmhhdmluZyBhdmcoc2FsYXJ5KSA+IChzZWxlY3QgYXZnKHNhbGFyeSkgZnJvbSBpbnN0cnVjdG9yKTsK', b64d('R3JvdXAgdnMgb3ZlcmFsbCBhdmVyYWdlIChUeXBlIDMp'), b64d('RGVwYXJ0bWVudHMgd2hvc2UgYXZlcmFnZSBpbnN0cnVjdG9yIHNhbGFyeSBpcyBoaWdoZXIgdGhhbiB0aGUgYXZlcmFnZSBzYWxhcnkgb2YgKiphbGwqKiBpbnN0cnVjdG9ycy4KT3V0cHV0OiAoZGVwdF9uYW1lKQ=='), b64d('YGhhdmluZyBhdmcoc2FsYXJ5KSA+IChzZWxlY3QgYXZnKHNhbGFyeSkgZnJvbSBpbnN0cnVjdG9yKWA='), b64d(''), 'VGhlIHN1YnF1ZXJ5IGhhcyBubyBgZ3JvdXAgYnlgLCBzbyBpdCByZXR1cm5zIGEgc2luZ2xlIG51bWJlcjogdGhlIGF2ZXJhZ2Ugb3ZlciBhbGwgaW5zdHJ1Y3RvcnMuIEl0IGlzIG5vdCBjb3JyZWxhdGVkOyBpdCBydW5zIG9uY2Uu'),
  ('D10', false, 'c2VsZWN0IHJvdW5kKG1heChhdmdfc2FsYXJ5KSwgMikgYXMgbWF4X2F2Zwpmcm9tIChzZWxlY3QgZGVwdF9uYW1lLCBhdmcoc2FsYXJ5KSBhcyBhdmdfc2FsYXJ5CiAgICAgIGZyb20gaW5zdHJ1Y3RvcgogICAgICBncm91cCBieSBkZXB0X25hbWUpIGFzIGRlcHRfYXZnOwo=', b64d('U3VicXVlcnkgaW4gRlJPTQ=='), b64d('VGhlIGhpZ2hlc3QgcGVyLWRlcGFydG1lbnQgYXZlcmFnZSBzYWxhcnksIHJvdW5kZWQgdG8gMiBkZWNpbWFscy4gVXNlIGEgc3VicXVlcnkgaW4gYEZST01gLgpPdXRwdXQ6IChtYXhfYXZnKQ=='), b64d('YG1heChhdmcoLi4uKSlgIGlzIG5vdCBhbGxvd2VkLiBBdmVyYWdlIHBlciBkZXBhcnRtZW50IGluIGEgc3VicXVlcnkgZmlyc3QsIHRoZW4gbWF4Lg=='), b64d(''), 'WW91IGNhbm5vdCBuZXN0IGFnZ3JlZ2F0ZXMgKGBtYXgoYXZnKHNhbGFyeSkpYCBpcyBhbiBlcnJvcikuIENvbXB1dGUgdGhlIHBlci1kZXBhcnRtZW50IGF2ZXJhZ2VzIGFzIGEgZGVyaXZlZCB0YWJsZSBmaXJzdCwgdGhlbiB0YWtlIHRoZSBtYXggb2YgdGhhdC4gUG9zdGdyZVNRTCAxNCByZXF1aXJlcyBhbiBhbGlhcyBmb3IgYSBzdWJxdWVyeSBpbiBgZnJvbWAgKGBhcyBkZXB0X2F2Z2ApLg=='),
  ('D11', false, 'd2l0aCBzZWNfY291bnQgYXMgKAogIHNlbGVjdCBJRCwgY291bnQoKikgYXMgbnVtX3NlY3Rpb25zCiAgZnJvbSB0ZWFjaGVzCiAgZ3JvdXAgYnkgSUQKKQpzZWxlY3QgaS5uYW1lLCBjLm51bV9zZWN0aW9ucwpmcm9tIHNlY19jb3VudCBjCmpvaW4gaW5zdHJ1Y3RvciBpIG9uIGkuSUQgPSBjLklECndoZXJlIGMubnVtX3NlY3Rpb25zID4gKHNlbGVjdCBhdmcobnVtX3NlY3Rpb25zKSBmcm9tIHNlY19jb3VudCk7Cg==', b64d('V0lUSCAvIENURSAoVHlwZSA4KQ=='), b64d('VXNpbmcgYFdJVEhgOiBpbnN0cnVjdG9ycyB3aG8gdGF1Z2h0IG1vcmUgc2VjdGlvbnMgKHJvd3MgaW4gYHRlYWNoZXNgKSB0aGFuIHRoZSBhdmVyYWdlIG51bWJlciBvZiBzZWN0aW9ucyBwZXIgaW5zdHJ1Y3RvciAoYXZlcmFnZSBvdmVyIGluc3RydWN0b3JzIHdobyB0YXVnaHQgYXQgbGVhc3Qgb25lIHNlY3Rpb24pLgpPdXRwdXQ6IChuYW1lLCBudW1fc2VjdGlvbnMp'), b64d('YHdpdGggc2VjX2NvdW50IGFzIChzZWxlY3QgSUQsIGNvdW50KCopIC4uLiBncm91cCBieSBJRClgLCB0aGVuIHVzZSBpdCB0d2ljZS4='), b64d(''), 'YHdpdGggbmFtZSBhcyAoLi4uKWAgZGVmaW5lcyBhIHRlbXBvcmFyeSBuYW1lZCByZXN1bHQgZm9yIHRoaXMgb25lIHF1ZXJ5LiBJdCBpcyB1c2VkIHR3aWNlOiBvbmNlIGluIHRoZSBtYWluIGBmcm9tYCwgYW5kIG9uY2UgaW5zaWRlIHRoZSBzY2FsYXIgc3VicXVlcnkgdGhhdCBjb21wdXRlcyB0aGUgYXZlcmFnZS4gVGhhdCBpcyB0aGUgbWFpbiBhZHZhbnRhZ2Ugb3ZlciByZXBlYXRpbmcgdGhlIGBncm91cCBieWAgc3VicXVlcnku'),
  ('D12', true, 'c2VsZWN0IGQuZGVwdF9uYW1lLAogICAgICAgKHNlbGVjdCBjb3VudCgqKSBmcm9tIGluc3RydWN0b3IgaSB3aGVyZSBpLmRlcHRfbmFtZSA9IGQuZGVwdF9uYW1lKSBhcyBudW1faW5zdHJ1Y3RvcnMsCiAgICAgICAoc2VsZWN0IGNvdW50KCopIGZyb20gc3R1ZGVudCBzIHdoZXJlIHMuZGVwdF9uYW1lID0gZC5kZXB0X25hbWUpIGFzIG51bV9zdHVkZW50cwpmcm9tIGRlcGFydG1lbnQgZApvcmRlciBieSBkLmRlcHRfbmFtZTsK', b64d('VGhlIGRvdWJsZS1jb3VudGluZyB0cmFw'), b64d('Rm9yICoqZXZlcnkqKiBkZXBhcnRtZW50LCBpbmNsdWRpbmcgb25lcyB3aXRoIG5vYm9keTogdGhlIG51bWJlciBvZiBpbnN0cnVjdG9ycyBhbmQgdGhlIG51bWJlciBvZiBzdHVkZW50cy4gQ2hlY2sgQ29tcC4gU2NpLiBieSBoYW5kIGZpcnN0IQpPdXRwdXQ6IChkZXB0X25hbWUsIG51bV9pbnN0cnVjdG9ycywgbnVtX3N0dWRlbnRzKSDCtyAqKk9yZGVyOioqIGRlcHRfbmFtZQ=='), b64d('Sm9pbmluZyBpbnN0cnVjdG9yIEFORCBzdHVkZW50IHRvIGRlcGFydG1lbnQgbXVsdGlwbGllcyByb3dzLiBDb3VudCBlYWNoIGluIGl0cyBvd24gc2NhbGFyIHN1YnF1ZXJ5Lg=='), b64d(''), 'VGhlIHRlbXB0aW5nIHF1ZXJ5IGlzOgpgYGBzcWwKc2VsZWN0IGQuZGVwdF9uYW1lLCBjb3VudChpLklEKSwgY291bnQocy5JRCkKZnJvbSBkZXBhcnRtZW50IGQKbGVmdCBqb2luIGluc3RydWN0b3IgaSBvbiBpLmRlcHRfbmFtZSA9IGQuZGVwdF9uYW1lCmxlZnQgam9pbiBzdHVkZW50IHMgb24gcy5kZXB0X25hbWUgPSBkLmRlcHRfbmFtZQpncm91cCBieSBkLmRlcHRfbmFtZTsKYGBgCkl0IGlzIHdyb25nLiBDb21wLiBTY2kuIGhhcyAzIGluc3RydWN0b3JzIGFuZCA0IHN0dWRlbnRzLCBzbyB0aGUgam9pbnMgcHJvZHVjZSAzIMOXIDQgPSAxMiByb3dzLCBhbmQgYm90aCBjb3VudHMgc2F5IDEyLiBKb2luaW5nIHR3byBpbmRlcGVuZGVudCAiY2hpbGQiIHRhYmxlcyBtdWx0aXBsaWVzIHJvd3MuIEZpeGVzOiBjb3VudCBlYWNoIHRhYmxlIGluIGl0cyBvd24gc2NhbGFyIHN1YnF1ZXJ5ICh0aGUgc29sdXRpb24gYWJvdmUpLCBvciB1c2UgYGNvdW50KGRpc3RpbmN0IGkuSUQpLCBjb3VudChkaXN0aW5jdCBzLklEKWAu'),
  ('E1', false, 'c2VsZWN0IGMuY291cnNlX2lkLCBwLnByZXJlcV9pZApmcm9tIGNvdXJzZSBjCmxlZnQgb3V0ZXIgam9pbiBwcmVyZXEgcCBvbiBjLmNvdXJzZV9pZCA9IHAuY291cnNlX2lkOwo=', b64d('TEVGVCBPVVRFUiBKT0lO'), b64d('RXZlcnkgY291cnNlIHdpdGggZWFjaCBvZiBpdHMgcHJlcmVxdWlzaXRlczsgYSBjb3Vyc2Ugd2l0aCBubyBwcmVyZXF1aXNpdGUgYXBwZWFycyBvbmNlIHdpdGggTlVMTC4KT3V0cHV0OiAoY291cnNlX2lkLCBwcmVyZXFfaWQp'), b64d('YGxlZnQgb3V0ZXIgam9pbmA='), b64d(''), 'QW4gaW5uZXIgam9pbiBkcm9wcyBldmVyeSBjb3Vyc2UgdGhhdCBoYXMgbm8gcHJlcmVxIHJvdy4gYGxlZnQgam9pbmAga2VlcHMgZXZlcnkgcm93IG9mIHRoZSBsZWZ0IHRhYmxlIGFuZCBmaWxscyB0aGUgcmlnaHQgc2lkZSB3aXRoIE5VTEwgd2hlbiB0aGVyZSBpcyBubyBtYXRjaC4='),
  ('E2', true, 'c2VsZWN0IGkubmFtZSBhcyBpbnN0cnVjdG9yLCBzLm5hbWUgYXMgc3R1ZGVudApmcm9tIGluc3RydWN0b3IgaQpsZWZ0IGpvaW4gYWR2aXNvciBhIG9uIGEuaV9JRCA9IGkuSUQKbGVmdCBqb2luIHN0dWRlbnQgcyBvbiBzLklEID0gYS5zX0lECm9yZGVyIGJ5IGkubmFtZSwgcy5uYW1lOwo=', b64d('Q2hhaW4gb2Ygb3V0ZXIgam9pbnM='), b64d('RXZlcnkgaW5zdHJ1Y3RvciB3aXRoIHRoZSBuYW1lcyBvZiB0aGUgc3R1ZGVudHMgdGhleSBhZHZpc2U7IGFuIGluc3RydWN0b3Igd2hvIGFkdmlzZXMgbm9ib2R5IGFwcGVhcnMgb25jZSB3aXRoIE5VTEwuCk91dHB1dDogKGluc3RydWN0b3IsIHN0dWRlbnQpIMK3ICoqT3JkZXI6KiogaW5zdHJ1Y3RvciwgdGhlbiBzdHVkZW50'), b64d('VHdvIGpvaW5zIGluIGEgY2hhaW4sIGFuZCBib3RoIG11c3QgYmUgbGVmdCBqb2lucy4='), b64d(''), 'Qm90aCBqb2lucyBtdXN0IGJlIG91dGVyLiBJZiB5b3Ugd3JpdGUgYGxlZnQgam9pbiBhZHZpc29yIC4uLiBqb2luIHN0dWRlbnQgLi4uYCwgdGhlIHNlY29uZCAoaW5uZXIpIGpvaW4gdGhyb3dzIGF3YXkgdGhlIE5VTEwgcm93cyB0aGF0IHRoZSBmaXJzdCBsZWZ0IGpvaW4ganVzdCBjcmVhdGVkLCBhbmQgaW5zdHJ1Y3RvcnMgd2hvIGFkdmlzZSBub2JvZHkgZGlzYXBwZWFyIGFnYWluLiBPbmNlIGEgY2hhaW4gZ29lcyAibGVmdCIsIGV2ZXJ5IGxhdGVyIGpvaW4gdGhhdCBjb3VsZCBmYWlsIHRvIG1hdGNoIG11c3QgYmUgImxlZnQiIHRvby4='),
  ('E3', false, 'c2VsZWN0IGkubmFtZSwgdC5jb3Vyc2VfaWQKZnJvbSBpbnN0cnVjdG9yIGkKbGVmdCBqb2luIHRlYWNoZXMgdCBvbiB0LklEID0gaS5JRAogICAgICAgICAgICAgICAgICAgYW5kIHQuc2VtZXN0ZXIgPSAnRmFsbCcKICAgICAgICAgICAgICAgICAgIGFuZCB0LnllYXIgPSAyMDI2Owo=', b64d('T04gdnMgV0hFUkUgaW4gYW4gb3V0ZXIgam9pbg=='), b64d('RXZlcnkgaW5zdHJ1Y3RvciB3aXRoIHRoZSBjb3Vyc2VfaWQgb2YgZWFjaCBzZWN0aW9uIHRoZXkgdGVhY2ggaW4gKipGYWxsIDIwMjYqKjsgaW5zdHJ1Y3RvcnMgd2l0aCBubyBGYWxsIDIwMjYgc2VjdGlvbiBhcHBlYXIgb25jZSB3aXRoIE5VTEwuCk91dHB1dDogKG5hbWUsIGNvdXJzZV9pZCk='), b64d('VGhlIHRlcm0gY29uZGl0aW9uIGdvZXMgaW4gYG9uYCwgbm90IGB3aGVyZWAu'), b64d(''), 'VGhlIHRlcm0gY29uZGl0aW9uIG11c3QgYmUgaW4gYG9uYC4gSWYgeW91IG1vdmUgaXQgdG8gYHdoZXJlYDoKYGBgc3FsCi4uLiBsZWZ0IGpvaW4gdGVhY2hlcyB0IG9uIHQuSUQgPSBpLklECndoZXJlIHQuc2VtZXN0ZXIgPSAnRmFsbCcgYW5kIHQueWVhciA9IDIwMjYKYGBgCnRoZW4gZm9yIFd1IChubyBGYWxsIDIwMjYgc2VjdGlvbnMpIHRoZSBsZWZ0IGpvaW4gcHJvZHVjZXMgKFd1LCBOVUxMLi4uKSBhbmQgdGhlIGB3aGVyZWAgdGhlbiBjaGVja3MgYG51bGwgPSAnRmFsbCdgLCB3aGljaCBpcyB1bmtub3duLCBzbyB0aGUgcm93IGlzIHJlbW92ZWQuIFRoZSBvdXRlciBqb2luIHF1aWV0bHkgYmVjYW1lIGFuIGlubmVyIGpvaW4uCgotIGBvbmAgZGVjaWRlcyB3aGljaCByb3dzIG1hdGNoLiBOb24tbWF0Y2hpbmcgbGVmdCByb3dzIGFyZSBzdGlsbCBrZXB0LCB3aXRoIE5VTExzLgotIGB3aGVyZWAgZmlsdGVycyB0aGUgZmluYWwgam9pbmVkIHJvd3Mu'),
  ('E4', true, 'c2VsZWN0IGMuY291cnNlX2lkLCBjb3VudChzLnNlY19pZCkgYXMgbnVtX3NlY3Rpb25zCmZyb20gY291cnNlIGMKbGVmdCBqb2luIHNlY3Rpb24gcyBvbiBzLmNvdXJzZV9pZCA9IGMuY291cnNlX2lkCmdyb3VwIGJ5IGMuY291cnNlX2lkCm9yZGVyIGJ5IGMuY291cnNlX2lkOwo=', b64d('T3V0ZXIgam9pbiArIGNvdW50'), b64d('RXZlcnkgY291cnNlIHdpdGggdGhlIG51bWJlciBvZiBzZWN0aW9ucyBpdCBoYXMgZXZlciBoYWQgKDAgaWYgbm9uZSkuCk91dHB1dDogKGNvdXJzZV9pZCwgbnVtX3NlY3Rpb25zKSDCtyAqKk9yZGVyOioqIGNvdXJzZV9pZA=='), b64d('YGNvdW50KCopYCBjb3VudHMgdGhlIE5VTEwgcm93IGFzIDEuIENvdW50IGEgY29sdW1uIGZyb20gdGhlIHJpZ2h0IHRhYmxlIGluc3RlYWQu'), b64d(''), 'YGNvdW50KCopYCB3b3VsZCBzYXkgMSBmb3IgQklPLTM5OTogdGhlIGxlZnQgam9pbiBtYWRlIG9uZSByb3cgKEJJTy0zOTksIE5VTEwuLi4pIGFuZCBgY291bnQoKilgIGNvdW50cyByb3dzLiBgY291bnQocy5zZWNfaWQpYCBjb3VudHMgb25seSBub24tTlVMTCB2YWx1ZXMsIHNvIDAu'),
  ('E5', false, 'd2l0aCBmMjUgYXMgKHNlbGVjdCBkaXN0aW5jdCBjb3Vyc2VfaWQgZnJvbSBzZWN0aW9uIHdoZXJlIHNlbWVzdGVyID0gJ0ZhbGwnIGFuZCB5ZWFyID0gMjAyNSksCiAgICAgZjI2IGFzIChzZWxlY3QgZGlzdGluY3QgY291cnNlX2lkIGZyb20gc2VjdGlvbiB3aGVyZSBzZW1lc3RlciA9ICdGYWxsJyBhbmQgeWVhciA9IDIwMjYpCnNlbGVjdCBmMjUuY291cnNlX2lkIGFzIGluXzIwMjUsIGYyNi5jb3Vyc2VfaWQgYXMgaW5fMjAyNgpmcm9tIGYyNQpmdWxsIG91dGVyIGpvaW4gZjI2IG9uIGYyNS5jb3Vyc2VfaWQgPSBmMjYuY291cnNlX2lkOwo=', b64d('RlVMTCBPVVRFUiBKT0lO'), b64d('Q29tcGFyZSBGYWxsIDIwMjUgYW5kIEZhbGwgMjAyNjogb25lIHJvdyBwZXIgY291cnNlIG9mZmVyZWQgaW4gZWl0aGVyIHRlcm0sIHdpdGggdGhlIGNvdXJzZV9pZCB1bmRlciB0aGUgdGVybShzKSBpdCB3YXMgb2ZmZXJlZCBhbmQgTlVMTCB1bmRlciB0aGUgb3RoZXIuIFVzZSBgRlVMTCBPVVRFUiBKT0lOYC4KT3V0cHV0OiAoaW5fMjAyNSwgaW5fMjAyNik='), b64d('VHdvIENURXMgKG9uZSBwZXIgdGVybSkgYW5kIGBmdWxsIG91dGVyIGpvaW5gIHRoZW0gb24gY291cnNlX2lkLg=='), b64d(''), 'QSBmdWxsIG91dGVyIGpvaW4ga2VlcHMgdW5tYXRjaGVkIHJvd3MgZnJvbSBib3RoIHNpZGVzLiBDUy0zMTkgYW5kIE1VLTE5OSBhcHBlYXIgb25seSBvbiB0aGUgMjAyNiBzaWRlLCB3aXRoIE5VTEwgZm9yIDIwMjUu'),
  ('E6', false, 'c2VsZWN0IGQuZGVwdF9uYW1lLCBkLmJ1aWxkaW5nLAogICAgICAgY291bnQoaS5JRCkgYXMgbnVtX2luc3RydWN0b3JzLAogICAgICAgY29hbGVzY2Uoc3VtKGkuc2FsYXJ5KSwgMCkgYXMgdG90YWxfc2FsYXJ5CmZyb20gZGVwYXJ0bWVudCBkCmxlZnQgam9pbiBpbnN0cnVjdG9yIGkgb24gaS5kZXB0X25hbWUgPSBkLmRlcHRfbmFtZQpncm91cCBieSBkLmRlcHRfbmFtZSwgZC5idWlsZGluZzsK', b64d('QSB2aWV3IHdpdGggb3V0ZXIgam9pbiArIGFnZ3JlZ2F0ZXM='), b64d('Q3JlYXRlIGEgKip2aWV3KiogbmFtZWQgYGRlcHRfb3ZlcnZpZXdgIHdpdGggb25lIHJvdyBmb3IgKipldmVyeSoqIGRlcGFydG1lbnQ6IChkZXB0X25hbWUsIGJ1aWxkaW5nLCBudW1faW5zdHJ1Y3RvcnMsIHRvdGFsX3NhbGFyeSkuIE5vIGluc3RydWN0b3JzIOKGkiAwIGluc3RydWN0b3JzIGFuZCB0b3RhbCBgMGAgKG5vdCBgMC4wMGApLgpXcml0ZSB0aGUgYGNyZWF0ZSBvciByZXBsYWNlIHZpZXcgLi4uYCBpbiB0aGUgZWRpdG9yLiBSdW4gJiBTdWJtaXQgY3JlYXRlcyBpdCwgdGhlbiBjaGVja3MgYHNlbGVjdCAqIGZyb20gZGVwdF9vdmVydmlld2Au'), b64d('YGxlZnQgam9pbiBpbnN0cnVjdG9yYCwgYGNvdW50KGkuSUQpYCwgYGNvYWxlc2NlKHN1bShpLnNhbGFyeSksIDApYA=='), b64d('c2VsZWN0ICogZnJvbSBkZXB0X292ZXJ2aWV3'), 'VGhlIHNvbHV0aW9uIGNyZWF0ZXMgdGhlIHZpZXc6CmBgYHNxbApjcmVhdGUgb3IgcmVwbGFjZSB2aWV3IGRlcHRfb3ZlcnZpZXcgYXMKc2VsZWN0IGQuZGVwdF9uYW1lLCBkLmJ1aWxkaW5nLAogICAgICAgY291bnQoaS5JRCkgYXMgbnVtX2luc3RydWN0b3JzLAogICAgICAgY29hbGVzY2Uoc3VtKGkuc2FsYXJ5KSwgMCkgYXMgdG90YWxfc2FsYXJ5CmZyb20gZGVwYXJ0bWVudCBkCmxlZnQgam9pbiBpbnN0cnVjdG9yIGkgb24gaS5kZXB0X25hbWUgPSBkLmRlcHRfbmFtZQpncm91cCBieSBkLmRlcHRfbmFtZSwgZC5idWlsZGluZzsKYGBgCi0gTGVmdCBqb2luIHNvIE1hdGhlbWF0aWNzIChubyBpbnN0cnVjdG9ycykgc3RpbGwgZ2V0cyBhIHJvdy4KLSBgY291bnQoaS5JRClgIChub3QgYGNvdW50KCopYCkgZ2l2ZXMgMCBmb3IgTWF0aGVtYXRpY3MuCi0gYHN1bWAgb3ZlciBubyB2YWx1ZXMgaXMgTlVMTCwgbm90IDAuIGBjb2FsZXNjZSh4LCAwKWAgcmV0dXJucyB0aGUgZmlyc3Qgbm9uLU5VTEwgYXJndW1lbnQgKHNhbWUgYXMgYGNhc2Ugd2hlbiB4IGlzIG51bGwgdGhlbiAwIGVsc2UgeCBlbmRgKS4KLSBBIHZpZXcgc3RvcmVzIG9ubHkgdGhlIHF1ZXJ5LCBub3QgdGhlIGRhdGEuIEV2ZXJ5IGBzZWxlY3QgKiBmcm9tIGRlcHRfb3ZlcnZpZXdgIHJlLXJ1bnMgaXQuCgpUaGUgY2hlY2tlciBydW5zIHRoaXMgZXF1aXZhbGVudCBxdWVyeTo='),
  ('G1', false, 'c2VsZWN0IGQuZGVwdF9uYW1lLAogICAgICAgKHNlbGVjdCBjb3VudCgqKSBmcm9tIGluc3RydWN0b3IgaSB3aGVyZSBpLmRlcHRfbmFtZSA9IGQuZGVwdF9uYW1lKQpmcm9tIGRlcGFydG1lbnQgZDsK', b64d('ZGVwdF9oZWFkY291bnQoKTogU0VMRUNUIElOVE8='), b64d('V3JpdGUgYGRlcHRfaGVhZGNvdW50KGRuYW1lIHZhcmNoYXIpIHJldHVybnMgaW50ZWdlcmA6IHRoZSBudW1iZXIgb2YgaW5zdHJ1Y3RvcnMgaW4gdGhhdCBkZXBhcnRtZW50LiBVc2UgYFNFTEVDVCAuLi4gSU5UT2AuClJ1biAmIFN1Ym1pdCBjcmVhdGVzIHlvdXIgZnVuY3Rpb24sIHRoZW4gY2hlY2tzIGBzZWxlY3QgZGVwdF9uYW1lLCBkZXB0X2hlYWRjb3VudChkZXB0X25hbWUpIGZyb20gZGVwYXJ0bWVudGAu'), b64d('TGVjdHVyZSAwNydzIGB0b3RhbF9zdHVkZW50cygpYCBleGFtcGxlLCB3aXRoIGEgcGFyYW1ldGVyLg=='), b64d('c2VsZWN0IGRlcHRfbmFtZSwgZGVwdF9oZWFkY291bnQoZGVwdF9uYW1lKSBmcm9tIGRlcGFydG1lbnQ='), 'VGhlIHdvcmtlZCBzb2x1dGlvbiBmb3IgdGhpcyBzZXQgd2lsbCBiZSBwdWJsaXNoZWQgbGF0ZXIuIFVudGlsIHRoZW4sIHVzZSB0aGUgaGludCBhbmQgY29tcGFyZSB5b3VyIG91dHB1dCB3aXRoIHRoZSBleHBlY3RlZCBvdXRwdXQu'),
  ('G2', false, 'c2VsZWN0IG5hbWUsCiAgICAgICBjYXNlIHdoZW4gc2FsYXJ5IGlzIG51bGwgdGhlbiAndW5rbm93bicKICAgICAgICAgICAgd2hlbiBzYWxhcnkgPCA2MDAwMCB0aGVuICdqdW5pb3InCiAgICAgICAgICAgIHdoZW4gc2FsYXJ5IDwgODUwMDAgdGhlbiAnbWlkJwogICAgICAgICAgICBlbHNlICdzZW5pb3InCiAgICAgICBlbmQKZnJvbSBpbnN0cnVjdG9yOwo=', b64d('c2FsYXJ5X2JhbmQoKTogSUYgLyBFTFNJRg=='), b64d('V3JpdGUgYHNhbGFyeV9iYW5kKHNhbCBudW1lcmljKSByZXR1cm5zIHZhcmNoYXJgOiBgJ3Vua25vd24nYCBpZiBOVUxMLCBgJ2p1bmlvcidgIGJlbG93IDYwMDAwLCBgJ21pZCdgIGJlbG93IDg1MDAwLCBgJ3NlbmlvcidgIG90aGVyd2lzZS4gVXNlIGBJRiAvIEVMU0lGIC8gRUxTRWAu'), b64d('VGVzdCBOVUxMIGZpcnN0LiBgZW5kIGlmO2AgaXMgdHdvIHdvcmRzLg=='), b64d('c2VsZWN0IG5hbWUsIHNhbGFyeV9iYW5kKHNhbGFyeSkgZnJvbSBpbnN0cnVjdG9y'), 'VGhlIHdvcmtlZCBzb2x1dGlvbiBmb3IgdGhpcyBzZXQgd2lsbCBiZSBwdWJsaXNoZWQgbGF0ZXIuIFVudGlsIHRoZW4sIHVzZSB0aGUgaGludCBhbmQgY29tcGFyZSB5b3VyIG91dHB1dCB3aXRoIHRoZSBleHBlY3RlZCBvdXRwdXQu'),
  ('G3', false, 'c2VsZWN0IGQsCiAgICAgICBjYXNlIGQgd2hlbiAnTScgdGhlbiAnTW9uZGF5JwogICAgICAgICAgICAgIHdoZW4gJ1QnIHRoZW4gJ1R1ZXNkYXknCiAgICAgICAgICAgICAgd2hlbiAnVycgdGhlbiAnV2VkbmVzZGF5JwogICAgICAgICAgICAgIHdoZW4gJ1InIHRoZW4gJ1RodXJzZGF5JwogICAgICAgICAgICAgIHdoZW4gJ0YnIHRoZW4gJ0ZyaWRheScKICAgICAgICAgICAgICBlbHNlICd1bmtub3duJwogICAgICAgZW5kCmZyb20gKHZhbHVlcyAoJ00nKSwgKCdUJyksICgnVycpLCAoJ1InKSwgKCdGJyksICgnUycpLCAobnVsbCkpIGFzIHYoZCk7Cg==', b64d('ZGF5X25hbWUoKTogQ0FTRSBzdGF0ZW1lbnQ='), b64d('V3JpdGUgYGRheV9uYW1lKGQgdmFyY2hhcikgcmV0dXJucyB2YXJjaGFyYDogTeKGkk1vbmRheSwgVOKGklR1ZXNkYXksIFfihpJXZWRuZXNkYXksIFLihpJUaHVyc2RheSwgRuKGkkZyaWRheSwgYW55dGhpbmcgZWxzZSAoaW5jbC4gTlVMTCkg4oaSIHVua25vd24uIFVzZSBhIENBU0UgKipzdGF0ZW1lbnQqKiAoYGNhc2UgLi4uIGVuZCBjYXNlO2ApLg=='), b64d('YGNhc2UgZCB3aGVuICdNJyB0aGVuIHJlc3VsdCA6PSAnTW9uZGF5JzsgLi4uIGVsc2UgcmVzdWx0IDo9ICd1bmtub3duJzsgZW5kIGNhc2U7YA=='), b64d('c2VsZWN0IGQsIGRheV9uYW1lKGQpIGZyb20gKHZhbHVlcyAoJ00nKSwoJ1QnKSwoJ1cnKSwoJ1InKSwoJ0YnKSwoJ1MnKSwobnVsbCkpIGFzIHYoZCk='), 'VGhlIHdvcmtlZCBzb2x1dGlvbiBmb3IgdGhpcyBzZXQgd2lsbCBiZSBwdWJsaXNoZWQgbGF0ZXIuIFVudGlsIHRoZW4sIHVzZSB0aGUgaGludCBhbmQgY29tcGFyZSB5b3VyIG91dHB1dCB3aXRoIHRoZSBleHBlY3RlZCBvdXRwdXQu'),
  ('G4', false, 'c2VsZWN0IGkuSUQsCiAgICAgICAoc2VsZWN0IHJvdW5kKGF2ZyhuKSwgMikKICAgICAgICBmcm9tIChzZWxlY3QgKHNlbGVjdCBjb3VudCgqKQogICAgICAgICAgICAgICAgICAgICAgZnJvbSB0YWtlcyBrCiAgICAgICAgICAgICAgICAgICAgICB3aGVyZSBrLmNvdXJzZV9pZCA9IHQuY291cnNlX2lkIGFuZCBrLnNlY19pZCA9IHQuc2VjX2lkCiAgICAgICAgICAgICAgICAgICAgICAgIGFuZCBrLnNlbWVzdGVyID0gdC5zZW1lc3RlciBhbmQgay55ZWFyID0gdC55ZWFyKSBhcyBuCiAgICAgICAgICAgICAgZnJvbSB0ZWFjaGVzIHQKICAgICAgICAgICAgICB3aGVyZSB0LklEID0gaS5JRCkgeCkKZnJvbSBpbnN0cnVjdG9yIGk7Cg==', b64d('YXZnX2NsYXNzX3NpemUoKTogRk9SIGxvb3AgKyBhY2N1bXVsYXRvcg=='), b64d('V3JpdGUgYGF2Z19jbGFzc19zaXplKGlpZCB2YXJjaGFyKSByZXR1cm5zIG51bWVyaWNgOiB0aGUgYXZlcmFnZSBudW1iZXIgb2Ygc3R1ZGVudHMgKHRha2VzIHJvd3MpIHBlciBzZWN0aW9uIHRoZSBpbnN0cnVjdG9yIHRhdWdodCAoc2VjdGlvbnMgd2l0aCBubyBzdHVkZW50cyBjb3VudCBhcyAwKSwgcm91bmRlZCB0byAyIGRlY2ltYWxzOyBOVUxMIGlmIG5vIHNlY3Rpb25zLiBVc2UgYSAqKkZPUiBsb29wKiosIG5vIGBhdmcoKWAuClNhbml0eSBjaGVjazogQnJhbmR0ICg4MzgyMSkgaGFzIDQgc2VjdGlvbnMgd2l0aCAwLCAyLCAxIGFuZCAzIHN0dWRlbnRzLCBzbyAxLjUwLg=='), b64d('YGZvciBzZWMgaW4gc2VsZWN0IC4uLiBmcm9tIHRlYWNoZXMgdCB3aGVyZSB0LklEID0gaWlkIGxvb3AgLi4uIGVuZCBsb29wO2AsIHRoZW4gd2F0Y2ggb3V0IGZvciBpbnRlZ2VyIGRpdmlzaW9uLg=='), b64d('c2VsZWN0IElELCBhdmdfY2xhc3Nfc2l6ZShJRCkgZnJvbSBpbnN0cnVjdG9y'), 'VGhlIHdvcmtlZCBzb2x1dGlvbiBmb3IgdGhpcyBzZXQgd2lsbCBiZSBwdWJsaXNoZWQgbGF0ZXIuIFVudGlsIHRoZW4sIHVzZSB0aGUgaGludCBhbmQgY29tcGFyZSB5b3VyIG91dHB1dCB3aXRoIHRoZSBleHBlY3RlZCBvdXRwdXQu'),
  ('G5', false, 'c2VsZWN0IHQuSUQsIHQuY291cnNlX2lkLCB0LnNlY19pZCwgdC5zZW1lc3RlciwgdC55ZWFyLCBjLnRpdGxlCmZyb20gdGVhY2hlcyB0CmpvaW4gY291cnNlIGMgb24gYy5jb3Vyc2VfaWQgPSB0LmNvdXJzZV9pZDsK', b64d('c2VjdGlvbnNfdGF1Z2h0KCk6IFJFVFVSTlMgVEFCTEU='), b64d('V3JpdGUgYHNlY3Rpb25zX3RhdWdodChpaWQgdmFyY2hhcikgcmV0dXJucyB0YWJsZSAoY291cnNlX2lkIHZhcmNoYXIsIHNlY19pZCB2YXJjaGFyLCBzZW1lc3RlciB2YXJjaGFyLCB5ZWFyIG51bWVyaWMsIHRpdGxlIHZhcmNoYXIpYDogdGhlIHNlY3Rpb25zIHRoZSBpbnN0cnVjdG9yIHRhdWdodCwgd2l0aCB0aGUgY291cnNlIHRpdGxlLiBVc2UgYFJFVFVSTiBRVUVSWWAu'), b64d('QWxpYXMgZXZlcnkgdGFibGUgYW5kIHF1YWxpZnkgZXZlcnkgY29sdW1uIChgdC5jb3Vyc2VfaWRgKSwgb3IgeW91J2xsIGdldCAiY29sdW1uIHJlZmVyZW5jZSBpcyBhbWJpZ3VvdXMiLg=='), b64d('c2VsZWN0IGkuSUQsIHMuKiBmcm9tIGluc3RydWN0b3IgaSwgc2VjdGlvbnNfdGF1Z2h0KGkuSUQpIHM='), 'VGhlIHdvcmtlZCBzb2x1dGlvbiBmb3IgdGhpcyBzZXQgd2lsbCBiZSBwdWJsaXNoZWQgbGF0ZXIuIFVudGlsIHRoZW4sIHVzZSB0aGUgaGludCBhbmQgY29tcGFyZSB5b3VyIG91dHB1dCB3aXRoIHRoZSBleHBlY3RlZCBvdXRwdXQu'),
  ('G6', false, 'c2VsZWN0ICoKZnJvbSAodmFsdWVzICgnMjIyMjInLCA5NTAwMC4wMCwgOTYwMDAuMDApLAogICAgICAgICAgICAgKCczMzQ1NicsIDg3MDAwLjAwLCA4ODAwMC4wMCksCiAgICAgICAgICAgICAoJzQ0NDQ0JywgbnVsbCwgNzAwMDAuMDApKSBhcyB2KGlkLCBvbGRfc2FsYXJ5LCBuZXdfc2FsYXJ5KTsK', b64d('QXVkaXQgdHJpZ2dlciB3aXRoIE9MRCBhbmQgTkVX'), b64d('V3JpdGUgdHJpZ2dlciBmdW5jdGlvbiBgbG9nX3NhbGFyeV9jaGFuZ2UoKWAgYW5kIGEgdHJpZ2dlciBvbiBgaW5zdHJ1Y3RvcmAgKEFGVEVSIFVQREFURSwgRk9SIEVBQ0ggUk9XKSB0aGF0IGluc2VydHMgKElELCBvbGQgc2FsYXJ5LCBuZXcgc2FsYXJ5KSBpbnRvIGBzYWxhcnlfbG9nYCAqKm9ubHkgd2hlbiB0aGUgc2FsYXJ5IGNoYW5nZWQqKiwgaW5jbHVkaW5nIE5VTEwg4oaSIGEgdmFsdWUuClJ1biAmIFN1Ym1pdCBjcmVhdGVzIHRoZW0sIHRoZW4gcnVucyBhIHRlc3QgKGBnNl90ZXN0KClgKTogUGh5c2ljcyBpbnN0cnVjdG9ycyArMTAwMCwgUGFyayBOVUxMIOKGkiA3MDAwMCwgS2ltIHVwZGF0ZWQgd2l0aG91dCBhIHNhbGFyeSBjaGFuZ2UuIFRoZW4gaXQgY29tcGFyZXMgYHNhbGFyeV9sb2dgLiBUaGUgdGVzdCByZXNldHMgaXRzIGRhdGEgZWFjaCB0aW1lLg=='), b64d('YGlmIG5ldy5zYWxhcnkgaXMgZGlzdGluY3QgZnJvbSBvbGQuc2FsYXJ5IHRoZW4gaW5zZXJ0IC4uLjsgZW5kIGlmOyByZXR1cm4gbmV3O2A='), b64d('c2VsZWN0ICogZnJvbSBnNl90ZXN0KCk='), 'VGhlIHdvcmtlZCBzb2x1dGlvbiBmb3IgdGhpcyBzZXQgd2lsbCBiZSBwdWJsaXNoZWQgbGF0ZXIuIFVudGlsIHRoZW4sIHVzZSB0aGUgaGludCBhbmQgY29tcGFyZSB5b3VyIG91dHB1dCB3aXRoIHRoZSBleHBlY3RlZCBvdXRwdXQu'),
  ('G7', false, 'c2VsZWN0IGQuZGVwdF9uYW1lLCBjb3VudChpLklEKSwgY29hbGVzY2Uoc3VtKGkuc2FsYXJ5KSwgMCk6Om51bWVyaWMoMTIsMikKZnJvbSBkZXBhcnRtZW50IGQKbGVmdCBqb2luIGluc3RydWN0b3IgaSBvbiBpLmRlcHRfbmFtZSA9IGQuZGVwdF9uYW1lCmdyb3VwIGJ5IGQuZGVwdF9uYW1lOwo=', b64d('UmVjb21wdXRlIHRyaWdnZXIgKGxpa2UgdGhlIGxlY3R1cmUncyB1cGRhdGVfYnVkZ2V0KQ=='), b64d('V3JpdGUgdHJpZ2dlciBmdW5jdGlvbiBgcmVmcmVzaF9kZXB0X3N0YXRzKClgIGFuZCBhIHRyaWdnZXIgb24gYGluc3RydWN0b3JgIChBRlRFUiBJTlNFUlQgT1IgVVBEQVRFLCBGT1IgRUFDSCBST1cpIHRoYXQgcmVjb21wdXRlcyB0aGUgYGRlcHRfc3RhdHNgIHJvdyBvZiBgTkVXLmRlcHRfbmFtZWAgZnJvbSBgaW5zdHJ1Y3RvcmA6IHRoZSBjb3VudCBhbmQgdGhlIHN1bSBvZiBzYWxhcmllcyAoYSBkZXBhcnRtZW50IHdpdGggbm8ga25vd24gc2FsYXJpZXMgaGFzIHRvdGFsIDApLgpSdW4gJiBTdWJtaXQgcnVucyBgZzdfdGVzdCgpYDogaXQgaW5zZXJ0cyBOb2V0aGVyIChNYXRoZW1hdGljcywgTlVMTCBzYWxhcnkpIGFuZCBHYXVzcyAoTWF0aGVtYXRpY3MsIDk5MDAwKSwgZ2l2ZXMgTXVzaWMgYSByYWlzZSwgYW5kIGNvbXBhcmVzIGBkZXB0X3N0YXRzYCB3aXRoIHRoZSB0cnV0aC4='), b64d('YHN1bSgpYCBvZiBub3RoaW5nIGlzIE5VTEwsIG5vdCAwLCBhbmQgYHRvdGFsX3NhbGFyeWAgaXMgTk9UIE5VTEwu'), b64d('c2VsZWN0ICogZnJvbSBnN190ZXN0KCk='), 'VGhlIHdvcmtlZCBzb2x1dGlvbiBmb3IgdGhpcyBzZXQgd2lsbCBiZSBwdWJsaXNoZWQgbGF0ZXIuIFVudGlsIHRoZW4sIHVzZSB0aGUgaGludCBhbmQgY29tcGFyZSB5b3VyIG91dHB1dCB3aXRoIHRoZSBleHBlY3RlZCBvdXRwdXQu'),
  ('G8', false, 'c2VsZWN0IGQuZGVwdF9uYW1lLCBjb3VudChpLklEKSwgY29hbGVzY2Uoc3VtKGkuc2FsYXJ5KSwgMCk6Om51bWVyaWMoMTIsMikKZnJvbSBkZXBhcnRtZW50IGQKbGVmdCBqb2luIGluc3RydWN0b3IgaSBvbiBpLmRlcHRfbmFtZSA9IGQuZGVwdF9uYW1lCmdyb3VwIGJ5IGQuZGVwdF9uYW1lOwo=', b64d('UmVjb21wdXRlIHRyaWdnZXIsIGJvbnVzOiBtb3ZpbmcgZGVwYXJ0bWVudHM='), b64d('Qm9udXM6IHRoZSBzYW1lIHRlc3QsIHBsdXMgTW96YXJ0ICoqbW92ZXMqKiBmcm9tIE11c2ljIHRvIE1hdGhlbWF0aWNzLiBJZiBNdXNpYyBzdGlsbCBzaG93cyAxIGluc3RydWN0b3IsIHlvdXIgdHJpZ2dlciBvbmx5IHJlY29tcHV0ZXMgdGhlIG5ldyBkZXBhcnRtZW50LgpFeHRlbmQgYHJlZnJlc2hfZGVwdF9zdGF0cygpYCAoaGludDogYFRHX09QYCBhbmQgYE9MRGApLg=='), b64d('SW4gYW4gVVBEQVRFIHRyaWdnZXIsIGBvbGQuZGVwdF9uYW1lYCBpcyB0aGUgZGVwYXJ0bWVudCBiZWZvcmUgdGhlIGNoYW5nZS4gUmVjb21wdXRlIHRoYXQgb25lIHRvby4='), b64d('c2VsZWN0ICogZnJvbSBnN190ZXN0KHRydWUp'), 'VGhlIHdvcmtlZCBzb2x1dGlvbiBmb3IgdGhpcyBzZXQgd2lsbCBiZSBwdWJsaXNoZWQgbGF0ZXIuIFVudGlsIHRoZW4sIHVzZSB0aGUgaGludCBhbmQgY29tcGFyZSB5b3VyIG91dHB1dCB3aXRoIHRoZSBleHBlY3RlZCBvdXRwdXQu'),
  ('L1.1', false, 'c2VsZWN0ICogZnJvbSBpdGVtOwo=', b64d('U0VMRUNUICo='), b64d('U2hvdyBldmVyeSBjb2x1bW4gb2YgZXZlcnkgaXRlbS4KT3V0cHV0OiAoaXRlbV9pZCwgaXRlbV9uYW1lLCBwcmljZSk='), b64d('YCpgIGluIHRoZSBzZWxlY3QgbGlzdCBtZWFucyAiYWxsIGNvbHVtbnMiLg=='), b64d(''), 'YCpgIG1lYW5zICJhbGwgY29sdW1ucyIuIEZpbmUgZm9yIGV4cGxvcmluZywgYnV0IG9uIHRoZSBleGFtIGFsd2F5cyBsaXN0IGV4YWN0bHkgdGhlIGNvbHVtbnMgdGhlIHF1ZXN0aW9uJ3MgT3V0cHV0IGFza3MgZm9yLg=='),
  ('L1.2', false, 'c2VsZWN0IGl0ZW1fbmFtZSwgcHJpY2UKZnJvbSBpdGVtCndoZXJlIHByaWNlID4gNTA7Cg==', b64d('V0hFUkUgd2l0aCBhIGNvbXBhcmlzb24='), b64d('SXRlbXMgdGhhdCBjb3N0IG1vcmUgdGhhbiA1MC4KT3V0cHV0OiAoaXRlbV9uYW1lLCBwcmljZSk='), b64d('Q29tcGFyaXNvbiBpbiBgd2hlcmVgOiBgcHJpY2UgPiA1MGAuIE51bWJlcnMgaGF2ZSBubyBxdW90ZXMu'), b64d(''), 'Q29tcGFyaXNvbiBvcGVyYXRvcnM6IGA9ICA8PiAgPCAgPiAgPD0gID49YCAoYCE9YCBhbHNvIHdvcmtzIGluIFBvc3RncmVTUUwpLiBOdW1iZXJzIGFyZSB3cml0dGVuIHdpdGhvdXQgcXVvdGVzLg=='),
  ('L1.3', false, 'c2VsZWN0IGJ1eWVyX25hbWUsIGNpdHkKZnJvbSBidXllcgp3aGVyZSBjaXR5IGluICgnU2VvdWwnLCAnQnVzYW4nKTsK', b64d('SU4gKGEgbGlzdCk='), b64d('QnV5ZXJzIHdobyBsaXZlIGluIFNlb3VsIG9yIEJ1c2FuLiBVc2UgYElOYC4KT3V0cHV0OiAoYnV5ZXJfbmFtZSwgY2l0eSk='), b64d('YHdoZXJlIGNpdHkgaW4gKCdTZW91bCcsICdCdXNhbicpYC4gVGV4dCB2YWx1ZXMgbmVlZCBzaW5nbGUgcXVvdGVzLg=='), b64d(''), 'YGNpdHkgaW4gKCdTZW91bCcsICdCdXNhbicpYCBpcyBzaG9ydCBmb3IgYGNpdHkgPSAnU2VvdWwnIG9yIGNpdHkgPSAnQnVzYW4nYC4gVGV4dCB2YWx1ZXMgYWx3YXlzIGdvIGluIHNpbmdsZSBxdW90ZXMu'),
  ('L1.4', true, 'c2VsZWN0IGl0ZW1fbmFtZSwgcHJpY2UKZnJvbSBpdGVtCndoZXJlIHByaWNlIGJldHdlZW4gMjUgYW5kIDYwCm9yZGVyIGJ5IHByaWNlOwo=', b64d('QkVUV0VFTiArIE9SREVSIEJZ'), b64d('SXRlbXMgdGhhdCBjb3N0IGJldHdlZW4gMjUgYW5kIDYwIChpbmNsdXNpdmUpLCBjaGVhcGVzdCBmaXJzdC4KT3V0cHV0OiAoaXRlbV9uYW1lLCBwcmljZSkgwrcgKipPcmRlcjoqKiBwcmljZSBhc2NlbmRpbmc='), b64d('YGJldHdlZW4gMjUgYW5kIDYwYCBpbmNsdWRlcyBib3RoIGVuZHMuIFNvcnRpbmcgZ29lcyBsYXN0OiBgb3JkZXIgYnkgcHJpY2VgLg=='), b64d(''), 'YGJldHdlZW4gMjUgYW5kIDYwYCBpbmNsdWRlcyBib3RoIGVuZHMuIGBvcmRlciBieSBwcmljZWAgc29ydHMgYXNjZW5kaW5nIGJ5IGRlZmF1bHQgKGBhc2NgKTsgYWRkIGBkZXNjYCBmb3IgZGVzY2VuZGluZy4gYG9yZGVyIGJ5YCBpcyBhbHdheXMgdGhlIGxhc3QgY2xhdXNlLg=='),
  ('L1.5', false, 'c2VsZWN0IGJ1eWVyX2lkLCBidXllcl9uYW1lCmZyb20gYnV5ZXIKd2hlcmUgcGhvbmUgaXMgbnVsbDsK', b64d('SVMgTlVMTA=='), b64d('QnV5ZXJzIHdob3NlIHBob25lIG51bWJlciBpcyB1bmtub3duLgpPdXRwdXQ6IChidXllcl9pZCwgYnV5ZXJfbmFtZSk='), b64d('VW5rbm93biA9IE5VTEwuIGA9IG51bGxgIG5ldmVyIG1hdGNoZXM7IHRoZXJlIGlzIGEgc3BlY2lhbCBvcGVyYXRvciBmb3IgaXQu'), b64d(''), 'YHBob25lID0gbnVsbGAgaXMgbmV2ZXIgdHJ1ZSwgYmVjYXVzZSBhbnkgY29tcGFyaXNvbiB3aXRoIE5VTEwgZ2l2ZXMgKnVua25vd24qLiBBbHdheXMgYGlzIG51bGxgIC8gYGlzIG5vdCBudWxsYC4='),
  ('L1.6', false, 'c2VsZWN0IGRpc3RpbmN0IGNpdHkKZnJvbSBidXllcjsK', b64d('RElTVElOQ1Q='), b64d('RXZlcnkgY2l0eSB3aGVyZSBhdCBsZWFzdCBvbmUgYnV5ZXIgbGl2ZXMsIHdpdGhvdXQgZHVwbGljYXRlcy4KT3V0cHV0OiAoY2l0eSk='), b64d('T25lIGtleXdvcmQgcmlnaHQgYWZ0ZXIgYHNlbGVjdGAgcmVtb3ZlcyBkdXBsaWNhdGUgcm93cy4='), b64d(''), 'V2l0aG91dCBgZGlzdGluY3RgLCBTZW91bCBhbmQgQnVzYW4gd291bGQgZWFjaCBhcHBlYXIgdHdpY2UgKHR3byBidXllcnMgbGl2ZSB0aGVyZSku'),
  ('L1.7', false, 'c2VsZWN0IGl0ZW1fbmFtZQpmcm9tIGl0ZW0Kd2hlcmUgaXRlbV9uYW1lIGxpa2UgJ00lJzsK', b64d('TElLRSB3aXRoICU='), b64d('SXRlbXMgd2hvc2UgbmFtZSBzdGFydHMgd2l0aCBhIGNhcGl0YWwgTS4KT3V0cHV0OiAoaXRlbV9uYW1lKQ=='), b64d('YGxpa2VgIHdpdGggYCVgLCB3aGljaCBtYXRjaGVzIGFueSB0ZXh0IChhbHNvIGVtcHR5KS4gTElLRSBpcyBjYXNlLXNlbnNpdGl2ZS4='), b64d(''), 'YCVgID0gYW55IG51bWJlciBvZiBjaGFyYWN0ZXJzIChhbHNvIHplcm8pLiBgJ00lJ2AgPSBzdGFydHMgd2l0aCBNLiBMSUtFIGlzIGNhc2Utc2Vuc2l0aXZlOiBgJ20lJ2AgZmluZHMgbm90aGluZy4='),
  ('L1.8', false, 'c2VsZWN0IGJ1eWVyX25hbWUKZnJvbSBidXllcgp3aGVyZSBidXllcl9uYW1lIGxpa2UgJ19fX18nOwo=', b64d('TElLRSB3aXRoIF8='), b64d('QnV5ZXJzIHdob3NlIG5hbWUgaXMgZXhhY3RseSA0IGxldHRlcnMgbG9uZy4gVXNlIGBMSUtFYC4KT3V0cHV0OiAoYnV5ZXJfbmFtZSk='), b64d('YF9gIG1hdGNoZXMgZXhhY3RseSBvbmUgY2hhcmFjdGVyLg=='), b64d(''), 'YF9gID0gZXhhY3RseSBvbmUgY2hhcmFjdGVyLCBzbyBmb3VyIHVuZGVyc2NvcmVzID0gZXhhY3RseSBmb3VyIGNoYXJhY3RlcnMu'),
  ('L1.9', true, 'c2VsZWN0IG9yZGVyX25vLCByZWNlaXZlZApmcm9tIG9yZGVycwp3aGVyZSBzaGlwcGVkID0gJ04nCm9yZGVyIGJ5IHJlY2VpdmVkIGRlc2M7Cg==', b64d('RmlsdGVyIG9uIGEgZmxhZywgbmV3ZXN0IGZpcnN0'), b64d('T3JkZXJzIHRoYXQgaGF2ZSBub3QgYmVlbiBzaGlwcGVkIHlldCAoYHNoaXBwZWRgIGlzIGAnTidgKSwgbmV3ZXN0IGZpcnN0LgpPdXRwdXQ6IChvcmRlcl9ubywgcmVjZWl2ZWQpIMK3ICoqT3JkZXI6KiogcmVjZWl2ZWQgZGVzY2VuZGluZw=='), b64d('YHNoaXBwZWRgIGlzIHRleHQsIHNvIGAnTidgIG5lZWRzIHF1b3Rlcy4gTmV3ZXN0IGZpcnN0ID0gYGRlc2NgLg=='), b64d(''), 'YHNoaXBwZWRgIGlzIGEgb25lLWxldHRlciB0ZXh0IGNvbHVtbiwgc28gdGhlIHZhbHVlIG5lZWRzIHF1b3RlczogYCdOJ2AuIERhdGVzIHNvcnQgY2hyb25vbG9naWNhbGx5OyBgZGVzY2AgcHV0cyB0aGUgbmV3ZXN0IGZpcnN0Lg=='),
  ('L1.10', false, 'c2VsZWN0IGl0ZW1fbmFtZSwgcm91bmQocHJpY2UgKiAwLjksIDIpIGFzIHNhbGVfcHJpY2UKZnJvbSBpdGVtOwo=', b64d('QXJpdGhtZXRpYyBhbmQgYW4gYWxpYXM='), b64d('RXZlcnkgaXRlbSB3aXRoIGl0cyBwcmljZSBhZnRlciBhIDEwJSBkaXNjb3VudCwgcm91bmRlZCB0byAyIGRlY2ltYWxzLCBpbiBhIGNvbHVtbiBjYWxsZWQgYHNhbGVfcHJpY2VgLgpPdXRwdXQ6IChpdGVtX25hbWUsIHNhbGVfcHJpY2Up'), b64d('YHJvdW5kKHByaWNlICogMC45LCAyKSBhcyBzYWxlX3ByaWNlYA=='), b64d(''), 'WW91IGNhbiBjb21wdXRlIGluIGBzZWxlY3RgLiBgYXMgc2FsZV9wcmljZWAgbmFtZXMgdGhlIHJlc3VsdCBjb2x1bW4uIGByb3VuZCh4LCAyKWAgcm91bmRzIHRvIDIgZGVjaW1hbHM7IHdpdGhvdXQgaXQgeW91J2QgZ2V0IDEwODAuMDAwLg=='),
  ('L1.11', true, 'c2VsZWN0IG9yZGVyX25vLCBpdGVtX2lkLCBxdHkKZnJvbSBvcmRlcl9kZXRhaWxzCndoZXJlIHF0eSA+IDEwCm9yZGVyIGJ5IHF0eSBkZXNjLCBvcmRlcl9ubzsK', b64d('U29ydGluZyBieSB0d28ga2V5cw=='), b64d('T3JkZXIgbGluZXMgd2l0aCBhIHF1YW50aXR5IGFib3ZlIDEwLiBMYXJnZXN0IHF1YW50aXR5IGZpcnN0OyBpZiB0d28gbGluZXMgaGFkIHRoZSBzYW1lIHF1YW50aXR5LCBzbWFsbGVyIG9yZGVyX25vIGZpcnN0LgpPdXRwdXQ6IChvcmRlcl9ubywgaXRlbV9pZCwgcXR5KSDCtyAqKk9yZGVyOioqIHF0eSBkZXNjZW5kaW5nLCB0aGVuIG9yZGVyX25v'), b64d('YG9yZGVyIGJ5YCBjYW4gbGlzdCBzZXZlcmFsIGNvbHVtbnMsIGVhY2ggd2l0aCBpdHMgb3duIGBhc2NgL2BkZXNjYC4='), b64d(''), 'U29ydCBieSBxdHkgKGxhcmdlc3QgZmlyc3QpOyBvbmx5IHJvd3Mgd2l0aCB0aGUgc2FtZSBxdHkgd291bGQgdGhlbiBiZSBvcmRlcmVkIGJ5IG9yZGVyX25vLiBgZGVzY2AgYmVsb25ncyBvbmx5IHRvIGBxdHlgLg=='),
  ('L1.12', false, 'c2VsZWN0IGJ1eWVyX2lkLCBidXllcl9uYW1lLCBjaXR5CmZyb20gYnV5ZXIKd2hlcmUgKGNpdHkgPSAnU2VvdWwnIG9yIGNpdHkgPSAnQnVzYW4nKQogIGFuZCBidXllcl9uYW1lIGxpa2UgJ0ElJzsK', b64d('QU5EIGJpbmRzIHRpZ2h0ZXIgdGhhbiBPUg=='), b64d('QnV5ZXJzIHdobyBsaXZlIGluIFNlb3VsIG9yIEJ1c2FuICoqYW5kKiogd2hvc2UgbmFtZSBzdGFydHMgd2l0aCAnQScuClRyeSBpdCB3aXRob3V0IHBhcmVudGhlc2VzIGZpcnN0IGFuZCBzdWJtaXQuIFRoZW4gdGhpbmsgYWJvdXQgd2h5LgpPdXRwdXQ6IChidXllcl9pZCwgYnV5ZXJfbmFtZSwgY2l0eSk='), b64d('YGFuZGAgaXMgZXZhbHVhdGVkIGJlZm9yZSBgb3JgIChsaWtlIMOXIGJlZm9yZSArKS4gR3JvdXAgdGhlIHR3byBjaXRpZXMgd2l0aCBwYXJlbnRoZXNlcy4='), b64d(''), 'V2l0aG91dCBwYXJlbnRoZXNlcywgYGNpdHkgPSAnU2VvdWwnIG9yIGNpdHkgPSAnQnVzYW4nIGFuZCBidXllcl9uYW1lIGxpa2UgJ0ElJ2AgbWVhbnMgYGNpdHkgPSAnU2VvdWwnIG9yIChjaXR5ID0gJ0J1c2FuJyBhbmQgYnV5ZXJfbmFtZSBsaWtlICdBJScpYDogQU5EIGlzIGV2YWx1YXRlZCBmaXJzdCwgbGlrZSDDlyBiZWZvcmUgKyBpbiBtYXRoLiBUaGF0IGFkZHMgRGFuYSAoU2VvdWwsIG5vdCBhbiBBKS4gVXNlIHBhcmVudGhlc2VzIHdoZW5ldmVyIHlvdSBtaXggQU5EIGFuZCBPUi4=');

select question, result from verify_key() where result not like 'PASS%';
select count(*) as questions_loaded from answer_key;

reset client_min_messages;
