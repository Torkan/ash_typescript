import { listTodos } from "./generated";

// Test 1: Simple field selection
async function testSimpleFields() {
  const result = await listTodos({
    fields: ["id", "title", "status"]
  });

  // These should all have proper types now (not 'never')
  const todo = result[0];
  const id: string = todo.id;
  const title: string = todo.title;
  const status: string | null | undefined = todo.status;

  console.log("Simple fields test passed:", { id, title, status });
}

// Test 2: Calculation with load-through
async function testCalculationLoadThrough() {
  const result = await listTodos({
    fields: [
      "id",
      {
        self: {
          load: ["id", "title"]
        }
      }
    ]
  });

  const todo = result[0];
  const id: string = todo.id;

  // This should be { id: string; title: string } | null | undefined
  const self = todo.self;

  if (self) {
    const selfId: string = self.id;
    const selfTitle: string = self.title;
    console.log("Calculation load-through test passed:", { selfId, selfTitle });
  }
}

// Test 3: Calculation with arguments and load-through
async function testCalculationWithArgs() {
  const result = await listTodos({
    fields: [
      "id",
      {
        self: {
          input: { prefix: "TEST_" },
          load: ["title", "status", { user: ["name", "email"] }]
        }
      }
    ]
  });

  const todo = result[0];
  if (todo.self) {
    const title: string = todo.self.title;
    const status: string | null | undefined = todo.self.status;

    if (todo.self.user) {
      const userName: string = todo.self.user.name;
      const userEmail: string = todo.self.user.email;
      console.log("Calculation with args test passed:", { title, userName, userEmail });
    }
  }
}

// Test 4: Mixed simple and complex fields
async function testMixedFields() {
  const result = await listTodos({
    fields: [
      "id",
      "title",
      "is_overdue",
      "comment_count",
      { user: ["id", "name"] },
      { comments: ["content", "author_name"] }
    ]
  });

  const todo = result[0];
  const id: string = todo.id;
  const title: string = todo.title;
  const isOverdue: boolean | null | undefined = todo.is_overdue;
  const commentCount: number = todo.comment_count;

  if (todo.user) {
    const userId: string = todo.user.id;
    const userName: string = todo.user.name;
    console.log("User loaded:", { userId, userName });
  }

  if (todo.comments) {
    const firstComment = todo.comments[0];
    if (firstComment) {
      const content: string = firstComment.content;
      const authorName: string = firstComment.author_name;
      console.log("Comment loaded:", { content, authorName });
    }
  }
}

// Type inspection helpers
type SimpleFieldsResult = Awaited<ReturnType<typeof testSimpleFields>>;
type CalculationResult = Awaited<ReturnType<typeof testCalculationLoadThrough>>;
type CalculationWithArgsResult = Awaited<ReturnType<typeof testCalculationWithArgs>>;
type MixedFieldsResult = Awaited<ReturnType<typeof testMixedFields>>;

// Run all tests
async function runTests() {
  console.log("Running type inference tests...");

  try {
    await testSimpleFields();
    await testCalculationLoadThrough();
    await testCalculationWithArgs();
    await testMixedFields();
    console.log("All tests completed successfully!");
  } catch (error) {
    console.error("Test failed:", error);
  }
}

// Export to prevent unused warnings
export { runTests };
