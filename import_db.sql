DROP TABLE users;
DROP TABLE questions;
DROP TABLE question_follows;
DROP TABLE replies;
DROP TABLE question_likes;

PRAGMA foreign_keys = ON;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);

CREATE TABLE questions(
  id INTEGER PRIMARY KEY,
  title TEXT,
  body TEXT,
  author_id INTEGER NOT NULL,
  FOREIGN KEY(author_id) REFERENCES users(id)
);

CREATE TABLE question_follows(
  id INTEGER PRIMARY KEY,
  user_id INTEGER,
  question_id INTEGER,
  FOREIGN KEY(user_id) REFERENCES users(id),
  FOREIGN KEY(question_id) REFERENCES questions(id)
);

CREATE TABLE replies(
  id INTEGER PRIMARY KEY,
  parent_id INTEGER,
  question_id INTEGER,
  user_id INTEGER, 
  body TEXT,
  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_likes(
  id INTEGER PRIMARY KEY,
  user_id INTEGER,
  question_id INTEGER,
  liked INTEGER,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO users 
  (fname, lname)
VALUES 
  ('Kevin', 'Bai'),
  ('Cindy', 'Ke');

INSERT INTO questions
  (title, body, author_id)
VALUES 
  ('SEND HELP', 'we have no food, or water', (SELECT id FROM users WHERE fname = "Kevin")),
  ('SOOOO many Questions', '??????????????', (SELECT id FROM users WHERE fname = "Cindy"));

INSERT INTO question_follows
(user_id, question_id)
VALUES
(1,1),
(2,1),
(2,2);

INSERT INTO replies
(parent_id, question_id, user_id, body)
VALUES
(NULL, 1, 2, 'I am coming, hold on'),
(1, 1, 1, 'okay'),
(NULL, 2, 1, 'Lets solve them together!'),
(3, 2, 2, 'sounds great');

INSERT INTO question_likes
(user_id, question_id, liked)
VALUES
(1, 1, 1),
(2, 1, 0),
(1, 2, 0);
