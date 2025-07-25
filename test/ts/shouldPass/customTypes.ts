// Custom Types Tests - shouldPass
// Tests for custom type field selection and usage

import {
  getTodo,
  createTodo,
  CreateTodoConfig,
} from "../generated";

// Test 0: Custom type field selection
export const customTypeTest = await getTodo({
  fields: ["id", "title", "priorityScore"],
});

// Type assertion: priorityScore should be number type (PriorityScore maps to number)
if (customTypeTest?.priorityScore) {
  const score: number = customTypeTest.priorityScore;
  console.log(`Priority score: ${score}`);
}

// Test 0.1: ColorPalette custom type field selection
export const colorPaletteTest = await getTodo({
  fields: ["id", "title", "colorPalette"],
});

// Type assertion: colorPalette should be ColorPalette type (custom type with complex structure)
if (colorPaletteTest?.colorPalette) {
  const palette: { primary: string; secondary: string; accent: string } = colorPaletteTest.colorPalette;
  const primary: string = palette.primary;
  const secondary: string = palette.secondary;
  const accent: string = palette.accent;
  console.log(`Color palette: primary=${primary}, secondary=${secondary}, accent=${accent}`);
}

// Test 5.1: Create operation with colorPalette custom type in input
export const createWithColorPalette = await createTodo({
  input: {
    title: "Color Palette Todo",
    status: "pending",
    userId: "user-id-123",
    colorPalette: {
      primary: "#FF5733",
      secondary: "#33FF57",
      accent: "#3357FF",
    },
  },
  fields: [
    "id",
    "title",
    "colorPalette",
    "createdAt",
  ],
});

// Type validation for created color palette todo
const createdColorPaletteId: string = createWithColorPalette.id;
const createdColorPaletteTitle: string = createWithColorPalette.title;
const createdAt: string = createWithColorPalette.createdAt;

if (createWithColorPalette.colorPalette) {
  const createdPalette: { primary: string; secondary: string; accent: string } = createWithColorPalette.colorPalette;
  const createdPrimary: string = createdPalette.primary;
  const createdSecondary: string = createdPalette.secondary;
  const createdAccent: string = createdPalette.accent;
}

console.log("Custom types tests should compile successfully!");