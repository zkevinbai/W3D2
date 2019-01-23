require 'sqlite3'
require 'singleton'
require 'byebug'

class QuestionsDatabase < SQLite3::Database
  include Singleton 
  def initialize 
    super('questions.db')
    self.type_translation = true 
    self.results_as_hash = true 
  end 
end 

class Users 
  attr_reader :id 
  attr_accessor :fname, :lname  

  def self.find_by_id(id)
    user = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL

    Users.new(user.first)
  end 
  
  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname'] 
  end 

  def self.find_by_name(fname, lname)
    user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT 
        *
      FROM 
        users 
      WHERE 
        fname = ? AND lname = ? 
    SQL

    Users.new(user.first)
  end 

  def authored_questions
    Questions.find_by_author_id(@id)
  end 

  def authored_replies
    Replies.find_by_user_id(@id)
  end

  def followed_questions
    QuestionFollows.followers_for_user_id(@id)
  end

  def liked_questions
    QuestionLikes.liked_questions_for_user_id(@id)
  end 

  def average_karma
    tot_questions = Questions.find_by_id(@id).length
    tot_likes = QuestionLikes.total_likes(@id)
    tot_likes/tot_questions
  end

  def save
    QuestionsDatabase.instance.execute(<<-SQL,@fname, @lname)
      INSERT INTO users
      (fname, lname)
      VALUES
      (?,?)
    SQL
  end 
end 

class Questions 
  attr_reader :id 
  attr_accessor :title, :body, :author_id  
  
  def self.find_by_id(id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL

    arr = []
      questions.each do |question|
        arr << Questions.new(question)
      end
    arr
  end 

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body'] 
    @author_id = options['author_id'] 
  end 
 
  def self.find_by_author_id(author_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT 
        *
      FROM 
        questions 
      WHERE 
        author_id = ? 
    SQL
    array = []
    questions.each do |question|
      array << Questions.new(question)
    end 
    array
  end 

  def self.most_followed(n)
    QuestionFollows.most_followed_questions(n)
  end 

  def self.most_liked(n)
    QuestionLikes.most_liked_questions(n)
  end

  def author
    Users.find_by_id(@author_id)
  end

  def replies
    Replies.find_by_question_id(@id)
  end 

  def followers 
    QuestionFollows.followers_for_question_id(@id)
  end

  def likers  
    QuestionLikes.likers_for_question_id(@id)
  end 

  def num_likes 
    QuestionLikes.num_likes_for_question_id(@id)
  end

  def save
    QuestionsDatabase.instance.execute(<<-SQL,@title, @body, @author_id)
      INSERT INTO users
      (title, body, author_id)
      VALUES
      (?,?,?)
    SQL
  end 
end 

class QuestionFollows 
  attr_reader :id 
  attr_accessor :user_id, :question_id

  def self.find_by_id(id)
    q_follows = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT 
        *
      FROM 
        question_follows 
      WHERE 
        id = ? 
    SQL
    
    QuestionFollows.new(q_follows.first)
  end 
  
  def self.followers_for_question_id(question_id)
    followers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        fname, lname 
      FROM 
        users 
      JOIN 
        question_follows ON 
        users.id = question_follows.user_id 
      WHERE 
        question_follows.question_id = ? 
    SQL
    
    arr = []
    followers.each do |follower|
      arr << Users.new(follower)
    end 
    arr 
  end 

  def self.followers_for_user_id(user_id)
    followers = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT 
        title, body, author_id
      FROM 
        questions
      JOIN 
        question_follows ON 
        questions.id = question_follows.question_id
      WHERE 
        question_follows.user_id = ? 
    SQL
    
    arr = []
    followers.each do |follower|
      arr << Questions.new(follower)
    end 
    arr 
  end 

  def self.most_followed_questions(n)
    mfq = QuestionsDatabase.instance.execute(<<-SQL, n)
     SELECT 
        *
      FROM
        questions
      JOIN
        question_follows ON
        questions.id = question_follows.question_id
      GROUP BY 
        question_id
      ORDER BY
        COUNT(question_id) DESC
      LIMIT 1
        OFFSET ?-1
    SQL

    Questions.new(mfq.first)
  end

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id'] 
  end

  
end 

class Replies 
  attr_reader :id 
  attr_accessor :parent_id, :question_id, :user_id, :body

  def self.find_by_id(id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT 
        *
      FROM 
        replies 
      WHERE 
        id = ? 
    SQL

    Replies.new(reply.first)
  end 

  def initialize(options)
    @id = options['id']
    @parent_id = options['parent_id']
    @question_id = options['question_id'] 
    @user_id = options['user_id']
    @body = options['body'] 
  end

  def self.find_by_user_id(user_id)
    replys = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT 
        * 
      FROM 
        replies 
      WHERE 
        user_id = ?
    SQL
    array = []
    replys.each do |reply| 
      array << Replies.new(reply)
    end 
    array
  end 
 
  def self.find_by_question_id(question_id)
    replys = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT 
        * 
      FROM 
        replies 
      WHERE 
        question_id = ?
    SQL
    array = []
    replys.each do |reply| 
      array << Replies.new(reply)
    end 
    array
  end 

  def author
    User.find_by_id(@user_id)
  end 

  def question
    Questions.find_by_id(@question_id)
  end 

  def parent_reply
    Replies.find_by_id(@parent_id)
  end

  def child_replies
    replies = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_id = ?
    SQL

    array = []
    replies.each do |reply|
      array << Replies.new(reply)
    end
    array
  end

  def save
    QuestionsDatabase.instance.execute(<<-SQL,@parent_id, @question_id, @user_id, @body)
      INSERT INTO users
      (parent_id, question_id, user_id, body)
      VALUES
      (?,?,?,?)
    SQL
  end 

end 

class QuestionLikes 
  attr_reader :id 
  attr_accessor :user_id, :question_id, :liked 

  def self.find_by_id(id)
    q_like = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT 
        * 
      FROM 
        question_likes 
      WHERE 
        id = ? 
    SQL
    QuestionLikes.new(q_like.first)
  end 

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id'] 
    @liked = options['liked'] 
  end

  def self.likers_for_question_id(question_id)
    likers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT 
        fname, lname
      FROM 
        users 
      JOIN
        question_likes ON 
        users.id = question_likes.user_id
      WHERE 
        question_likes.question_id = ? 
    SQL
    
    arr = []
    likers.each do |liker|
      arr << Users.new(liker)
    end 
    arr 
  end 
  
  def self.num_likes_for_question_id(question_id)
     likers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT 
        COUNT(*)
      FROM 
        users 
      JOIN
        question_likes ON 
        users.id = question_likes.user_id
      WHERE 
        question_likes.question_id = ? 
    SQL
    
    likers.first["COUNT(*)"]

  end 

  def self.liked_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
     SELECT 
       title, body, author_id 
     FROM 
       questions
     JOIN 
       question_likes ON 
       questions.id = question_likes.question_id
     WHERE 
       question_likes.user_id = ? 
     SQL
     
     arr = []
     questions.each do |question|
      arr << Questions.new(question)
     end 
     arr 
  end 

  def self.most_liked_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        title, body, author_id
      FROM
        questions
      JOIN
        question_likes ON
        questions.id = question_likes.question_id
      GROUP BY
        questions.id
      ORDER BY
        COUNT(questions.id)
      LIMIT 
        1
      OFFSET ? - 1
    SQL

    Questions.new(questions.first)
  end

  def self.total_likes(author_id)
    total_likes = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT 
        COUNT(*)
      FROM 
        question_likes
      JOIN
        questions ON
        question_likes.question_id = questions.id
      WHERE
        questions.author_id = ?
    SQL

    total_likes.first['COUNT(*)']
  end
end 




