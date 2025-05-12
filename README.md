Social Media Analysis
Problem Statement
You are hired as a data analyst at Meta and asked to collaborate with Marketing team. Marketing teams wants to leverage Instagram's user data to develop targeted marketing strategies that will increase user engagement, retention, and acquisition. Provide insights and recommendations to address the following objectives.

Technologies Used
SQL (For quering and manipulating data)
Excel (For visualising the SQL results)

Data Description
The data can be inserted imprted to SQL using the queries given in the below link - "https://drive.google.com/file/d/1wSXXQboFYXgJXxccj4i-cKfIX5QtdPwH/view"

Running the queries will create 7 tables - users, photos, comments, likes, follows, tags and photo_tags.
The column means the following -
comments_id: unique identifier for each comment
comment_text: text content of a given comment
user_id: unique identifier for each user
photo_id: unique identifier for each photo
created_at: date of interaction in the form like, photos, tags
follower_id: user_id of the follower for a certain user
followee_id: user_id of followee for a certain user
tag_id: unique identifier for each tag
image_url: link to the image posted on the platform
username: username chosen by the user

Analysis and Insights
1. User Engagement: Most users fall into Low Likes (33%), Low Posts (53%), and Low Comments (64%) categories, while High Likes (13%), High Posts (4%), and High Comments (13%) have the least engagement.
2. Popular Tags: Tags like party (11.81%), food, fashion, and beauty are most used, while foodie and landscape are least used.
3. Targeted Ads: Ads should focus on high-engagement tags like smile (11.81%), beach (8.37%), and party (7.77%) during peak times—afternoon (11 AM - 12 PM) and evening (4 PM - 7 PM, 9 PM - 11 PM).
4. Loyal User Incentives: Reward loyal users with exclusive access, leaderboards, or tangible rewards, targeting those with posts > 0 to avoid fake accounts.
5. Re-engagement: Re-engage 26% zero-post users with personalized content and premium benefits for increased activity.
6. Influencer Strategy: Focus on influencers with a 60% engagement rate and 40% follower count for optimal collaboration.
