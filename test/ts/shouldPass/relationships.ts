// Relationships Tests - shouldPass
// Tests for relationship field selection in calculations

import {
  getTodo,
} from "../generated";

// Test 3: Self calculation with relationships in field selection
export const selfWithRelationships = await getTodo({
  fields: [
    "id",
    "title",
    { user: ["id", "email"] },
    {
      self: {
        args: { prefix: null }, // Test null prefix
        fields: [
          "id",
          "title",
          "status",
          {
            comments: ["id", "content", "rating"],
            user: ["id", "name", "email"],
          },
          {
            self: {
              args: { prefix: "nested_" },
              fields: [
                "priority",
                "tags",
                {
                  user: ["id", "name"],
                  comments: ["id", "authorName"],
                },
              ],
            },
          },
        ],
      },
    },
  ],
});

// Type validation for relationships in calculations
if (selfWithRelationships?.self) {
  // Outer self should have the specified relationships
  const selfUser = selfWithRelationships.self.user;
  const selfUserId: string = selfUser.id;
  const selfUserName: string = selfUser.name;
  const selfUserEmail: string = selfUser.email;

  const selfComments = selfWithRelationships.self.comments;
  if (selfComments.length > 0) {
    const firstComment = selfComments[0];
    const commentId: string = firstComment.id;
    const commentContent: string = firstComment.content;
    const commentRating: number | null | undefined = firstComment.rating;
  }

  // Nested self should have its specified relationships
  if (selfWithRelationships.self.self) {
    const nestedSelfUser = selfWithRelationships.self.self.user;
    const nestedUserId: string = nestedSelfUser.id;
    const nestedUserName: string = nestedSelfUser.name;

    const nestedComments = selfWithRelationships.self.self.comments;
    if (nestedComments.length > 0) {
      const nestedComment = nestedComments[0];
      const nestedCommentId: string = nestedComment.id;
      const nestedAuthorName: string = nestedComment.authorName;
    }
  }
}

console.log("Relationships tests should compile successfully!");