import {
  listTodos,
  createTodo,
  createUser,
  updateTodo,
  validateUpdateTodo,
} from "./generated";

const listTodosResult = await listTodos({
  fields: [
    "id",
    "comment_count",
    "is_overdue",
    {
      comments: [
        "id",
        "content",
        {
          user: [
            "id",
            "email",
            {
              todos: [
                "id",
                "title",
                "status",
                {
                  comments: ["id", "content"],
                },
              ],
            },
          ],
        },
      ],
      self: {
        load: [
          "title",
          "status",
          {
            user: ["name", "email"],
          },
        ],
      },
    },
  ],
});

type ExpectedListTodosResultType = Array<{
  id: string;
  is_overdue?: boolean | null;
  comment_count: number;
  comments: {
    id: string;
    content: string;
    user: {
      id: string;
      email: string;
      todos: {
        id: string;
        title: string;
        status?: string | null;
        comments?: {
          id: string;
          content: string;
        }[];
      }[];
    };
  }[];
  self?: {
    title: string;
    status?: string | null;
    user: {
      name: string;
      email: string;
    };
  } | null;
}>;

const listTodosResultTest: ExpectedListTodosResultType = listTodosResult;

const createUserResult = await createUser({
  input: {
    name: "User",
    email: "email@example.com",
  },
  fields: ["id", "email", "name"],
});

type ExpectedCreateUserResultType = {
  id: string;
  name: string;
  email: string;
};

const createUserResultTodo: ExpectedCreateUserResultType = createUserResult;

const createTodoResult = await createTodo({
  input: {
    title: "New Todo",
    status: "finished",
    user_id: createUserResultTodo.id,
  },
  fields: [
    "id",
    "title",
    "status",
    "user_id",
    { user: ["id", "email"], comments: ["id", "content"] },
  ],
});

type ExpectedCreateTodoResultType = {
  id: string;
  title: string;
  status?: string | null;
  user_id: string;
  user: {
    id: string;
    email: string;
  };
  comments: {
    id: string;
    content: string;
  }[];
};

const createTodoResultTest: ExpectedCreateTodoResultType = createTodoResult;

const updateTodoResult = await updateTodo({
  primaryKey: createTodoResult.id,
  input: {
    title: "Updated Todo",
    tags: ["tag1", "tag2"],
  },
  fields: [],
});

const validateUpdateTodoResult = await validateUpdateTodo(createTodoResult.id, {
  title: "Updated Todo",
  tags: ["tag1", "tag2"],
});

// Showcase sophisticated load statement capabilities
const sophisticatedLoadResult = await listTodos({
  fields: [
    "id",
    "title",
    "is_overdue", // Simple calculation as string
    "comment_count", // Aggregate as string
    {
      // Nested relationships
      user: ["id", "name", "email"],
      comments: [
        "id",
        "content",
        {
          user: ["name"], // Deeply nested relationship
        },
      ],
      // Load-through calculation that returns a struct
      self: {
        load: [
          "title",
          "status",
          "due_date",
          {
            user: ["name", "email"],
            comments: ["content"],
          },
        ],
      },
    },
  ],
});

type ExpectedSophisticatedLoadResultType = Array<{
  id: string;
  title: string;
  is_overdue?: boolean | null;
  comment_count: number;
  user: {
    id: string;
    name: string;
    email: string;
  };
  comments: {
    id: string;
    content: string;
    user: {
      name: string;
    };
  }[];
  self?: {
    title: string;
    status?: string | null;
    due_date?: string | null;
    user: {
      name: string;
      email: string;
    };
    comments: {
      content: string;
    }[];
  } | null;
}>;

const sophisticatedLoadTest: ExpectedSophisticatedLoadResultType =
  sophisticatedLoadResult;

// Test calculation with input arguments and load-through behavior
const calculationWithArgsResult = await listTodos({
  fields: [
    "id",
    "title",
    {
      self: {
        input: { prefix: "TEST_" },
        load: [
          "title",
          "status",
          "is_overdue",
          {
            user: ["name", "email"],
            comments: ["content", "author_name"],
          },
        ],
      },
    },
  ],
});

type ExpectedCalculationWithArgsResultType = Array<{
  id: string;
  title: string;
  self?: {
    title: string;
    status?: string | null;
    is_overdue?: boolean | null;
    user: {
      name: string;
      email: string;
    };
    comments: {
      content: string;
      author_name: string;
    }[];
  } | null;
}>;

const calculationWithArgsTest: ExpectedCalculationWithArgsResultType =
  calculationWithArgsResult;

// Test specific field type inference - only id and self should be available
const specificFieldsResult = await updateTodo({
  primaryKey: "foo",
  input: { title: "foo" },
  fields: ["id", { self: { load: ["id"], input: { prefix: "prefix" } } }],
});

type ExpectedSpecificFieldsResultType = {
  id: string;
  self?: {
    id: string;
  } | null;
};

const specificFieldsTest: ExpectedSpecificFieldsResultType =
  specificFieldsResult;

// This should cause a TypeScript error if uncommented (accessing non-loaded field):
// const shouldError = specificFieldsResult.title;

// Ultra-simple test to debug the type resolution issue
const ultraSimple = await updateTodo({
  primaryKey: "foo",
  input: { title: "foo" },
  fields: ["id"],
});

// This should work
const ultraSimpleId = ultraSimple.id;

// Test just the self field without any other fields
const justSelf = await updateTodo({
  primaryKey: "foo",
  input: { title: "foo" },
  fields: [{ self: { load: ["id"] } }],
});

// Debug the self field type step by step
type JustSelfType = typeof justSelf;
