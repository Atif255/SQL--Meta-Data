
-- Are there any tables with duplicate or missing null values? If so, how would you handle them?

-- -- checking duplicates

SELECT comment_text, user_id, photo_id, created_at
FROM comments 
GROUP BY 1,2,3,4
HAVING COUNT(*) > 1;

SELECT follower_id, followee_id
FROM follows 
GROUP BY  1,2
HAVING COUNT(*) > 1;

SELECT user_id, photo_id
FROM likes
GROUP BY 1,2
HAVING COUNT(*) > 1;

SELECT photo_id, tag_id
FROM photo_tags
GROUP BY 1,2
HAVING COUNT(*) > 1;

SELECT image_url, user_id, created_dat
FROM photos
GROUP BY 1,2,3
HAVING COUNT(*) > 1;

SELECT tag_name, created_at
FROM tags
GROUP BY 1,2
HAVING COUNT(*) > 1;

SELECT username, created_at 
FROM users
GROUP BY 1,2
HAVING COUNT(*) > 1;

-- NO DUPLICATE VALUES

-- Checking NULL Values
SELECT * FROM comments 
WHERE 1 IS NULL OR 2 IS NULL OR 3 IS NULL OR 4 IS NULL OR 5 IS NULL ;


SELECT * FROM follows 
WHERE 1 IS NULL OR 2 IS NULL OR 3 IS NULL;


SELECT * FROM likes 
WHERE 1 IS NULL OR 2 IS NULL OR 3 IS NULL;

SELECT * FROM photo_tags
WHERE 1 IS NULL OR 2 IS NULL;

SELECT * FROM photos
WHERE 1 IS NULL OR 2 IS NULL OR 3 IS NULL OR 4 IS NULL;

SELECT * FROM tags
WHERE 1 IS NULL OR 2 IS NULL OR 3 IS NULL;

SELECT * FROM users
WHERE 1 IS NULL OR 2 IS NULL OR 3 IS NULL;

-- NO NULL VALUES
-- What is the distribution of user activity levels (e.g., number of posts, likes, comments) across the user base?

SELECT 
	u.id AS user_id,
    	username,
    	COUNT(DISTINCT p.id) AS photos_posted,
    	COUNT(DISTINCT c.photo_id) AS comments,
    	COUNT(DISTINCT l.photo_id) AS likes,
    	COUNT(DISTINCT pt.tag_id) AS tags
FROM users u 
LEFT JOIN photos p ON p.user_id=u.id
LEFT JOIN comments c ON c.user_id=u.id
LEFT JOIN likes l ON l.user_id=u.id
LEFT JOIN photo_tags pt ON pt.photo_id=p.id
GROUP BY user_id, username;

-- Calculate the average number of tags per post (photo_tags and photos tables)

with cte as (
select photo_id, count(tag_id) as count_of_tags
from photo_tags
group by photo_id)

select avg(count_of_tags) from cte;

-- Identify the top users with the highest engagement rates (likes, comments) on their posts and rank them.

WITH engagements AS(
SELECT 
    u.id,
    username,
    COUNT(DISTINCT l.user_id) AS likes,
    COUNT(DISTINCT c.user_id) AS comments    
FROM users u 
LEFT JOIN photos p ON u.id = p.user_id
JOIN likes l ON l.photo_id = p.id
JOIN comments c ON c.photo_id=p.id
GROUP BY 1,2
),

total_post as (
select user_id , COUNT(id) as number_of_posts
from photos
group by user_id )


select id, username, likes+comments as total_engagements, (likes+comments)/number_of_posts as engagement_rate_per_post,
dense_rank () over (order by (likes+comments)/number_of_posts desc) as `rank`

from engagements e
join total_post t on e.id = t.user_id

-- Which users have the highest number of followers and followings?

-- Highest Number of followers:

WITH followers_cte AS (
    SELECT 
        u.id,
        u.username,
        COUNT(f.follower_id) AS followers_count
    FROM users u
    LEFT JOIN follows f ON u.id = f.followee_id
    GROUP BY u.id, u.username
),
ranked_followers AS (
    SELECT *,
        DENSE_RANK() OVER (ORDER BY followers_count DESC) AS count_rank
    FROM followers_cte
)

SELECT id, username, followers_count
FROM ranked_followers
WHERE count_rank = 1
ORDER BY id;

-- Highest Number of following:

WITH followings_cte AS (
    SELECT 
        u.id,
        u.username,
        COUNT(f.followee_id) AS followings_count
    FROM users u
    LEFT JOIN follows f ON u.id = f.follower_id
    GROUP BY u.id, u.username
),
ranked_followings AS (
    SELECT *,
        DENSE_RANK() OVER (ORDER BY followings_count DESC) AS count_rank
    FROM followings_cte
)
SELECT id, username, followings_count
FROM ranked_followings
WHERE count_rank = 1
ORDER BY id;

-- Calculate the average engagement rate (likes, comments) per post for each user.

WITH engagements AS(
SELECT 
    u.id,
    username,
    COUNT(DISTINCT l.user_id) AS likes,
    COUNT(DISTINCT c.user_id) AS comments    
FROM users u 
LEFT JOIN photos p ON u.id = p.user_id
JOIN likes l ON l.photo_id = p.id
JOIN comments c ON c.photo_id=p.id
GROUP BY 1,2
),

total_post as (
select user_id , COUNT(id) as number_of_posts
from photos
group by user_id )

Select
Id,
username, 
likes+comments as total_engagements, 
(likes+comments)/number_of_posts as engagement_rate_per_post,
dense_rank () over (order by (likes+comments)/number_of_posts desc) as `rank`
from engagements e
join total_post t on e.id = t.user_id;

-- Get the list of users who have never liked any post (users and likes tables)--

WITH users_who_liked AS (
    SELECT DISTINCT user_id
    FROM likes
)
SELECT u.id, u.username
FROM users u
LEFT JOIN users_who_liked l ON u.id = l.user_id
WHERE l.user_id IS NULL;

-- How can you leverage user-generated content (posts, hashtags, photo tags) to create more personalized and engaging ad campaigns?

SELECT t.tag_name, COUNT(*) AS usage_count
FROM photo_tags pt
JOIN tags t ON pt.tag_id = t.id
GROUP BY t.tag_name
ORDER BY usage_count DESC
LIMIT 10;

WITH user_tags AS (
  SELECT p.user_id, t.tag_name, COUNT(*) AS tag_count
  FROM photos p
  JOIN photo_tags pt ON p.id = pt.photo_id
  JOIN tags t ON pt.tag_id = t.id
  GROUP BY p.user_id, t.tag_name
),
ranked_tags AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY tag_count DESC) AS rn
  FROM user_tags
)
SELECT user_id, tag_name, tag_count
FROM ranked_tags
WHERE rn = 1;

-- Are there any correlations between user activity levels and specific content types (e.g., photos, videos, reels)? How can this information guide content creation and curation strategies?

WITH user_activity AS (
  SELECT u.id AS user_id,
         COUNT(DISTINCT p.id) AS posts,
         COUNT(DISTINCT l.photo_id) AS likes,
         COUNT(DISTINCT c.id) AS comments
  FROM users u
  LEFT JOIN photos p ON u.id = p.user_id
  LEFT JOIN likes l ON u.id = l.user_id
  LEFT JOIN comments c ON u.id = c.user_id
  GROUP BY u.id
),
user_tag_counts AS (
  SELECT p.user_id, t.tag_name, COUNT(*) AS tag_usage
  FROM photos p
  JOIN photo_tags pt ON p.id = pt.photo_id
  JOIN tags t ON pt.tag_id = t.id
  GROUP BY p.user_id, t.tag_name
),
ranked_user_tags AS (
  SELECT user_id, tag_name, tag_usage,
         RANK() OVER (PARTITION BY user_id ORDER BY tag_usage DESC) AS tag_rank
  FROM user_tag_counts
),
top_tag_per_user AS (
  SELECT user_id, tag_name
  FROM ranked_user_tags
  WHERE tag_rank = 1
),
final_engagement AS (
  SELECT ua.user_id,
         ua.posts,
         ua.likes,
         ua.comments,
         (ua.posts + ua.likes + ua.comments) AS total_activity,
         tt.tag_name AS most_used_tag
  FROM user_activity ua
  LEFT JOIN top_tag_per_user tt ON ua.user_id = tt.user_id
)
SELECT *
FROM final_engagement
ORDER BY total_activity DESC;

-- Calculate the total number of likes, comments, and photo tags for each user.

WITH user_photos AS (
  SELECT u.id AS user_id, u.username, p.id AS photo_id
  FROM users u
  JOIN photos p ON u.id = p.user_id
),
photo_stats AS (
  SELECT up.user_id, up.username, up.photo_id,
         COUNT(DISTINCT l.user_id) AS likes,
         COUNT(DISTINCT c.id) AS comments,
         COUNT(DISTINCT pt.tag_id) AS tags
  FROM user_photos up
  LEFT JOIN likes l ON up.photo_id = l.photo_id
  LEFT JOIN comments c ON up.photo_id = c.photo_id
  LEFT JOIN photo_tags pt ON up.photo_id = pt.photo_id
  GROUP BY up.user_id, up.username, up.photo_id
),
user_engagement AS (
  SELECT user_id, username,
         SUM(likes) AS likes,
         SUM(comments) AS comments,
         SUM(tags) AS tags
  FROM photo_stats
  GROUP BY user_id, username
)
SELECT * 
FROM user_engagement
ORDER BY likes + comments + tags DESC;

-- Rank users based on their total engagement (likes, comments, shares) over a month.

WITH engagement AS (
  SELECT 
    u.id AS user_id,
    u.username,
    YEAR(p.created_dat) AS year,
    MONTH(p.created_dat) AS month,
    COUNT(DISTINCT c.id) + COUNT(DISTINCT l.user_id) AS total_engagement
  FROM users u
  LEFT JOIN photos p ON u.id = p.user_id
  LEFT JOIN comments c ON c.photo_id = p.id
  LEFT JOIN likes l ON l.photo_id = p.id
  GROUP BY u.id, u.username, YEAR(p.created_dat), MONTH(p.created_dat)
)
SELECT 
  user_id,  username,  year,  month,   total_engagement,
 DENSE_RANK() OVER (PARTITION BY year, month ORDER BY total_engagement DESC) AS engagement_rank
FROM engagement
where year is not null and month is not null
ORDER BY year, month, engagement_rank;

-- Retrieve the hashtags that have been used in posts with the highest average number of likes. Use a CTE to calculate the average likes for each hashtag first.

WITH photo_like_counts AS (
  SELECT 
    p.id AS photo_id,
    COUNT(DISTINCT l.user_id) AS likes_count
  FROM photos p
  LEFT JOIN likes l ON p.id = l.photo_id
  GROUP BY p.id
),
tag_likes AS (
  SELECT 
    t.tag_name,
    plc.likes_count
  FROM photo_tags pt
  JOIN tags t ON pt.tag_id = t.id
  JOIN photo_like_counts plc ON pt.photo_id = plc.photo_id
),
avg_likes_per_tag AS (
  SELECT 
    tag_name,
    AVG(likes_count) AS avg_likes
  FROM tag_likes
  GROUP BY tag_name
),
max_avg AS (
  SELECT MAX(avg_likes) AS max_avg_likes
  FROM avg_likes_per_tag
)
SELECT 
  a.tag_name,
  a.avg_likes
FROM avg_likes_per_tag a
JOIN max_avg m ON a.avg_likes = m.max_avg_likes;

-- Retrieve the users who have started following someone after being followed by that person+

WITH mutual_follows AS (
  SELECT 
    f1.follower_id AS user_id,
    f1.followee_id AS followed_back_user_id,
    f1.created_at AS follow_time,
    f2.created_at AS followed_by_time
  FROM follows f1
  JOIN follows f2 
    ON f1.follower_id = f2.followee_id 
   AND f1.followee_id = f2.follower_id
)
SELECT 
  user_id,
  followed_back_user_id,
  follow_time,
  followed_by_time
FROM mutual_follows
WHERE follow_time > followed_by_time;

-- Based on user engagement and activity levels, which users would you consider the most loyal or valuable? How would you reward or incentivize these users?

WITH user_posts AS (
  SELECT user_id, COUNT(*) AS total_posts
  FROM photos
  GROUP BY user_id
),
user_likes_received AS (
  SELECT p.user_id, COUNT(l.user_id) AS total_likes
  FROM photos p
  JOIN likes l ON p.id = l.photo_id
  GROUP BY p.user_id
),
user_comments_received AS (
  SELECT p.user_id, COUNT(c.id) AS total_comments
  FROM photos p
  JOIN comments c ON p.id = c.photo_id
  GROUP BY p.user_id
),
total_engagement AS (
  SELECT 
    u.id AS user_id,
    u.username,
    COALESCE(up.total_posts, 0) AS posts,
    COALESCE(ul.total_likes, 0) AS likes_received,
    COALESCE(uc.total_comments, 0) AS comments_received,
    COALESCE(up.total_posts, 0) + COALESCE(ul.total_likes, 0) + COALESCE(uc.total_comments, 0) AS total_engagement
  FROM users u
  LEFT JOIN user_posts up ON u.id = up.user_id
  LEFT JOIN user_likes_received ul ON u.id = ul.user_id
  LEFT JOIN user_comments_received uc ON u.id = uc.user_id
)

SELECT *
FROM total_engagement
ORDER BY total_engagement DESC
LIMIT 10;

-- For inactive users, what strategies would you recommend to re-engage them and encourage them to start posting or engaging again?

WITH user_likes AS (
  SELECT user_id, COUNT(*) AS like_count
  FROM likes
  GROUP BY user_id
),
user_comments AS (
  SELECT user_id, COUNT(*) AS comment_count
  FROM comments
  GROUP BY user_id
),
user_posts AS (
  SELECT user_id, COUNT(*) AS post_count
  FROM photos
  GROUP BY user_id
),
active_users AS (
  SELECT user_id FROM likes
  UNION
  SELECT user_id FROM comments
  UNION
  SELECT user_id FROM photos
)
SELECT 
  u.id AS user_id, 
  u.username, 
  COALESCE(ul.like_count, 0) AS total_likes,
  COALESCE(uc.comment_count, 0) AS total_comments,
  COALESCE(up.post_count, 0) AS total_posts
FROM users u
LEFT JOIN user_likes ul ON u.id = ul.user_id
LEFT JOIN user_comments uc ON u.id = uc.user_id
LEFT JOIN user_posts up ON u.id = up.user_id
LEFT JOIN active_users au ON u.id = au.user_id
WHERE au.user_id IS NULL;

-- Which hashtags or content topics have the highest engagement rates? How can this information guide content strategy and ad campaigns?

WITH photo_engagement AS (
  SELECT 
    p.id AS photo_id,
    COUNT(DISTINCT l.user_id) AS like_count,
    COUNT(DISTINCT c.id) AS comment_count
  FROM photos p
  LEFT JOIN likes l ON p.id = l.photo_id
  LEFT JOIN comments c ON p.id = c.photo_id
  GROUP BY p.id),
tag_engagement AS (
  SELECT 
    t.tag_name,
    AVG(pe.like_count + pe.comment_count) AS avg_engagement
  FROM photo_tags pt
  JOIN tags t ON pt.tag_id = t.id
  JOIN photo_engagement pe ON pt.photo_id = pe.photo_id
  GROUP BY t.tag_name
)
SELECT 
  tag_name,
  ROUND(avg_engagement, 2) AS avg_engagement
FROM tag_engagement
ORDER BY avg_engagement DESC
LIMIT 5;

-- Are there any patterns or trends in user engagement based on demographics (age, location, gender) or posting times? How can these insights inform targeted marketing campaigns?

SELECT
    p.id AS photo_id,
    u.username,
    WEEKDAY(p.created_dat) AS day_of_week,
    EXTRACT(HOUR FROM p.created_dat) AS hour_of_day,
    COUNT(DISTINCT l.user_id) AS likes_received,
    COUNT(DISTINCT c.id) AS comments_received
FROM photos p
JOIN users u ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY p.id, u.username, day_of_week, hour_of_day
ORDER BY day_of_week, hour_of_day;


-- Based on follower counts and engagement rates, which users would be ideal candidates for influencer marketing campaigns? How would you approach and collaborate with these influencers?

WITH follower_counts AS (
    SELECT followee_id AS user_id, COUNT(*) AS total_followers
    FROM follows
    GROUP BY followee_id
),
engagement_per_post AS (
    SELECT 
        p.user_id,
        p.id AS photo_id,
        COUNT(DISTINCT l.user_id) AS likes,
        COUNT(DISTINCT c.id) AS comments
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id, p.id
),
user_engagement_summary AS (
    SELECT 
        user_id,
        COUNT(photo_id) AS total_posts,
        SUM(likes) AS total_likes,
        SUM(comments) AS total_comments,
        (SUM(likes) + SUM(comments)) / NULLIF(COUNT(photo_id), 0) AS avg_engagement_rate
    FROM engagement_per_post
    GROUP BY user_id
),
influencer_candidates AS (
    SELECT 
        u.id AS user_id,
        u.username,
        fc.total_followers,
        ue.total_posts,
        ue.total_likes,
        ue.total_comments,
        ue.avg_engagement_rate
    FROM users u
    JOIN follower_counts fc ON u.id = fc.user_id
    JOIN user_engagement_summary ue ON u.id = ue.user_id
)
SELECT *
FROM influencer_candidates
ORDER BY total_followers DESC, avg_engagement_rate DESC
LIMIT 10;

-- Based on user behavior and engagement data, how would you segment the user base for targeted marketing campaigns or personalized recommendations?

WITH user_activity AS (
    SELECT 
        u.id AS user_id,
        u.username,
        COALESCE(p.post_count, 0) AS posts,
        COALESCE(l.likes_given, 0) AS likes,
        COALESCE(c.comments_given, 0) AS comments
    FROM users u
    LEFT JOIN (
        SELECT user_id, COUNT(*) AS post_count
        FROM photos
        GROUP BY user_id
    ) p ON u.id = p.user_id
    LEFT JOIN (
        SELECT user_id, COUNT(*) AS likes_given
        FROM likes
        GROUP BY user_id
    ) l ON u.id = l.user_id
    LEFT JOIN (
        SELECT user_id, COUNT(*) AS comments_given
        FROM comments
        GROUP BY user_id
    ) c ON u.id = c.user_id
),
segmented_users AS (
    SELECT *,
        CASE
            WHEN posts >= 5 AND (likes + comments) >= 15 THEN 'Highly Active'
            WHEN posts BETWEEN 2 AND 4 OR (likes + comments) BETWEEN 5 AND 14 THEN      'Moderately Active'
            WHEN posts = 1 OR (likes + comments) BETWEEN 1 AND 4 THEN 'Low Activity'
            ELSE 'Inactive'
        END AS user_category
    FROM user_activity
)
SELECT * FROM segmented_users;

