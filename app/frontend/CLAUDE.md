# Component Reference

This guide covers shadcn/ui component patterns and common import mistakes.

## Component Import Reference

| Component | Import Path | Exports | Notes |
|-----------|-------------|---------|-------|
| **Empty** | `@/components/ui/empty` | Empty, EmptyHeader, EmptyTitle, EmptyDescription, EmptyContent | Use slot components (no direct props) |
| **Field** | `@/components/ui/field` | Field, FieldLabel, FieldError, FieldDescription, FieldGroup, FieldSet, FieldLegend, FieldContent, FieldTitle, FieldSeparator | **No FieldInput export** |
| **Input** | `@/components/ui/input` | Input | Import separately from Field |
| **Textarea** | `@/components/ui/textarea` | Textarea | Import separately from Field |
| **Select** | `@/components/ui/select` | Select | Import separately from Field |
| **Button** | `@/components/ui/button` | Button | Standard button component |
| **Card** | `@/components/ui/card` | Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter | **Keep Form fully inside or outside Card** |
| **Form** | `@inertiajs/react` | Form | Inertia form component |
| **Link** | `@inertiajs/react` | Link | Inertia link component |

## Common Import Mistakes

### FieldInput Does Not Exist

The shadcn/ui `Field` component does **not** export `FieldInput`. Use `Input` from `@/components/ui/input` instead.

```tsx
// ❌ WRONG - FieldInput doesn't exist
import { Field, FieldLabel, FieldInput } from '@/components/ui/field';

// ✅ CORRECT - Import Input separately
import { Field, FieldLabel, FieldError } from '@/components/ui/field';
import { Input } from '@/components/ui/input';

// Usage
<Field>
  <FieldLabel>Email</FieldLabel>
  <Input name="email" type="email" />
  {errors?.email && <FieldError>{errors.email}</FieldError>}
</Field>
```

### Available Field Exports

**Field components:**
- `Field` - Wrapper component
- `FieldLabel` - Label for field
- `FieldError` - Error message display
- `FieldDescription` - Help text/description

**Field grouping:**
- `FieldGroup` - Group multiple fields
- `FieldSet` - Fieldset wrapper
- `FieldLegend` - Legend for fieldset
- `FieldContent` - Content wrapper
- `FieldTitle` - Title component
- `FieldSeparator` - Visual separator

**Separate imports needed:**
- `Input` from `@/components/ui/input`
- `Textarea` from `@/components/ui/textarea`
- `Select` from `@/components/ui/select`

## Empty State Pattern

Use `Empty` component with slot-based composition (no direct `title`/`description` props):

```tsx
import {
  Empty,
  EmptyHeader,
  EmptyTitle,
  EmptyDescription,
  EmptyContent
} from '@/components/ui/empty'
import { Button } from '@/components/ui/button'
import { Link } from '@inertiajs/react'

export default function ItemsIndex({ items }) {
  if (items.length === 0) {
    return (
      <Empty>
        <EmptyHeader>
          <EmptyTitle>No items found</EmptyTitle>
          <EmptyDescription>
            Get started by creating your first item.
          </EmptyDescription>
        </EmptyHeader>
        <EmptyContent>
          <Link href="/items/new">
            <Button>Create Item</Button>
          </Link>
        </EmptyContent>
      </Empty>
    )
  }

  // ... render items
}
```

## Form Field Patterns

### Basic Text Input

```tsx
import { Field, FieldLabel, FieldError } from '@/components/ui/field'
import { Input } from '@/components/ui/input'

<Field>
  <FieldLabel>Name</FieldLabel>
  <Input name="item[name]" defaultValue={item.name} />
  {errors?.name && <FieldError>{errors.name}</FieldError>}
</Field>
```

### Textarea

```tsx
import { Field, FieldLabel, FieldError, FieldDescription } from '@/components/ui/field'
import { Textarea } from '@/components/ui/textarea'

<Field>
  <FieldLabel>Description</FieldLabel>
  <FieldDescription>Optional description for your item</FieldDescription>
  <Textarea name="item[description]" defaultValue={item.description} rows={4} />
  {errors?.description && <FieldError>{errors.description}</FieldError>}
</Field>
```

### Select

```tsx
import { Field, FieldLabel, FieldError } from '@/components/ui/field'
import { Select } from '@/components/ui/select'

<Field>
  <FieldLabel>Category</FieldLabel>
  <Select name="item[category]" defaultValue={item.category}>
    <option value="">Select a category</option>
    <option value="electronics">Electronics</option>
    <option value="clothing">Clothing</option>
  </Select>
  {errors?.category && <FieldError>{errors.category}</FieldError>}
</Field>
```

### Checkbox

```tsx
import { Field, FieldLabel } from '@/components/ui/field'
import { Input } from '@/components/ui/input'

<Field>
  <label className="flex items-center gap-2">
    <Input type="checkbox" name="item[featured]" defaultChecked={item.featured} />
    <FieldLabel>Featured item</FieldLabel>
  </label>
</Field>
```

### File Upload

```tsx
import { Field, FieldLabel, FieldError, FieldDescription } from '@/components/ui/field'
import { Input } from '@/components/ui/input'

<Field>
  <FieldLabel>Attachment</FieldLabel>
  <FieldDescription>PDF, PNG, or JPG (max 10MB)</FieldDescription>
  <Input type="file" name="item[attachment]" accept=".pdf,.png,.jpg" />
  {errors?.attachment && <FieldError>{errors.attachment}</FieldError>}
</Field>
```

## Field Grouping

### FieldSet for Related Fields

```tsx
import {
  Field,
  FieldSet,
  FieldLegend,
  FieldLabel,
  FieldError
} from '@/components/ui/field'
import { Input } from '@/components/ui/input'

<FieldSet>
  <FieldLegend>Contact Information</FieldLegend>

  <Field>
    <FieldLabel>Email</FieldLabel>
    <Input type="email" name="contact[email]" />
    {errors?.email && <FieldError>{errors.email}</FieldError>}
  </Field>

  <Field>
    <FieldLabel>Phone</FieldLabel>
    <Input type="tel" name="contact[phone]" />
    {errors?.phone && <FieldError>{errors.phone}</FieldError>}
  </Field>
</FieldSet>
```

### FieldGroup for Horizontal Layout

```tsx
import { FieldGroup, Field, FieldLabel } from '@/components/ui/field'
import { Input } from '@/components/ui/input'

<FieldGroup>
  <Field>
    <FieldLabel>First Name</FieldLabel>
    <Input name="user[first_name]" />
  </Field>

  <Field>
    <FieldLabel>Last Name</FieldLabel>
    <Input name="user[last_name]" />
  </Field>
</FieldGroup>
```

## Complete Form Example

```tsx
import { Form } from '@inertiajs/react'
import { Field, FieldLabel, FieldError, FieldDescription } from '@/components/ui/field'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Button } from '@/components/ui/button'

type Props = {
  item: {
    name?: string
    description?: string
    price?: number
  }
  errors?: {
    name?: string
    description?: string
    price?: string
  }
}

export default function ItemForm({ item, errors }: Props) {
  return (
    <Form action="/items" method="post" resetOnSuccess>
      {({ processing }) => (
        <div className="space-y-6">
          <Field>
            <FieldLabel>Name</FieldLabel>
            <Input name="item[name]" defaultValue={item.name} />
            {errors?.name && <FieldError>{errors.name}</FieldError>}
          </Field>

          <Field>
            <FieldLabel>Description</FieldLabel>
            <FieldDescription>
              Provide a detailed description of the item
            </FieldDescription>
            <Textarea name="item[description]" defaultValue={item.description} />
            {errors?.description && <FieldError>{errors.description}</FieldError>}
          </Field>

          <Field>
            <FieldLabel>Price</FieldLabel>
            <Input
              type="number"
              name="item[price]"
              defaultValue={item.price}
              step="0.01"
            />
            {errors?.price && <FieldError>{errors.price}</FieldError>}
          </Field>

          <div className="flex gap-4">
            <Button type="submit" disabled={processing}>
              {processing ? 'Saving...' : 'Save Item'}
            </Button>
            <Button type="button" variant="outline">
              Cancel
            </Button>
          </div>
        </div>
      )}
    </Form>
  )
}
```

## Form and Card Component Nesting

**IMPORTANT**: Forms must be fully inside or fully outside Card components. Do not split Card structure across Form boundaries.

```tsx
// ❌ WRONG - Form breaks Card component hierarchy
<Card>
  <CardHeader>
    <CardTitle>Create an account</CardTitle>
  </CardHeader>
  <Form action={signupPath()} method="post">
    {({ processing }) => (
      <>
        <CardContent className="space-y-4">
          {/* Form fields */}
        </CardContent>
        <CardFooter>
          <Button type="submit">Submit</Button>
        </CardFooter>
      </>
    )}
  </Form>
</Card>

// ✅ CORRECT - Form inside CardContent
<Card>
  <CardHeader>
    <CardTitle>Create an account</CardTitle>
    <CardDescription>Enter your details to sign up for an account</CardDescription>
  </CardHeader>
  <CardContent>
    <Form action={signupPath()} method="post">
      {({ processing }) => (
        <div className="space-y-4">
          {/* Form fields */}
          <Button type="submit" disabled={processing}>
            {processing ? 'Submitting...' : 'Submit'}
          </Button>
        </div>
      )}
    </Form>
  </CardContent>
</Card>

// ✅ ALSO CORRECT - Form wraps entire Card
<Form action={signupPath()} method="post">
  {({ processing }) => (
    <Card>
      <CardHeader>
        <CardTitle>Create an account</CardTitle>
        <CardDescription>Enter your details to sign up for an account</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Form fields */}
      </CardContent>
      <CardFooter>
        <Button type="submit" disabled={processing}>
          {processing ? 'Submitting...' : 'Submit'}
        </Button>
      </CardFooter>
    </Card>
  )}
</Form>
```

### Why This Matters

- **Breaking Card's component structure causes styling and semantic issues**
- **Card components expect direct children in a specific order** (Header → Content → Footer)
- **Form's render function creates a new component boundary** that disrupts this hierarchy

**General rule:** Keep component hierarchies intact. If a parent component expects specific children structure (like Card), don't interrupt it with wrapper components like Form.

## Layout Components

### PersistentLayout

Used for pages that share navigation/header:

```tsx
import PersistentLayout from '@/layouts/PersistentLayout'

export default function Index({ items }) {
  return <div>{/* page content */}</div>
}

Index.layout = (page: React.ReactNode) => (
  <PersistentLayout children={page} />
)
```

### Custom Per-Page Layout

Override the layout for specific pages:

```tsx
import CustomLayout from '@/layouts/CustomLayout'

export default function SpecialPage() {
  return <div>{/* page content */}</div>
}

SpecialPage.layout = (page: React.ReactNode) => (
  <CustomLayout children={page} />
)
```

## TypeScript Types

### Page Props Type

```tsx
type Item = {
  id: number
  name: string
  description: string | null
  created_at: string
}

type Props = {
  item: Item
  errors?: Record<string, string>
}

export default function Show({ item, errors }: Props) {
  // ...
}
```

### Shared Props (from inertia_share)

```tsx
// Define in types/inertia.d.ts
declare module '@inertiajs/core' {
  interface PageProps {
    auth: {
      user: {
        id: number
        email: string
        name: string
      } | null
    }
    flash: {
      notice?: string
      alert?: string
    }
  }
}

// Access in components
import { usePage } from '@inertiajs/react'

export default function MyComponent() {
  const { auth, flash } = usePage().props

  return (
    <div>
      {auth.user && <p>Hello, {auth.user.name}</p>}
      {flash.notice && <div className="notice">{flash.notice}</div>}
    </div>
  )
}
```
