---
marp: true
theme: gaia
class: lead
paginate: true
backgroundColor: #ececd1
color: #141416
---

# HTML5 Basics for Medical Students
## Practical Lab: Basic Tags & Structure

**Time:** 45 Minutes Total (3 Tasks)  
**Level:** Beginner  
**Topic:** Medical Data Formatting

---

# General Instructions

- **Files Provided:** 
  1. `personal.html`
  2. `lists.html`
  3. `tables.html`
- **Styling Rule:** Do **not** use external CSS files. 
- **Color:** Use inline styles only where specified (e.g., `style="color:red"`).
- **Goal:** Create medical-themed content using basic HTML5 tags.

---

# Task 1: Future Doctor Profile

- **File:** `personal.html`
- **Topic:** Personal Information & Text Formatting
- **Time:** 15 Minutes
- **Objective:** Create a professional profile using headings, paragraphs, and text formatting.

---

# Task 1: Steps (1-4)

1. **Open** `personal.html`.
2. **Main Heading:** Add `<h1>` with your Full Name.
3. **Subheading:** Add `<h2>` with Specialization/Year.
   - *Example:* `<h2>5th Year Student | Cardiology</h2>`
4. **About Me:** 
   - Add `<h3>` "About Me".
   - Add `<p>` with 2 sentences.
   - Use `<strong>` for **main interest**.
   - Use `<em>` for *university name*.

---

# Task 1: Steps (5-8)

5. **Medical Formatting:**
   - Use `<sub>` for formulas (e.g., O<sub>2</sub>).
   - Use `<sup>` for units (e.g., m<sup>2</sup>).
6. **Contact Info:**
   - Add `<h3>` "Contact Information".
   - Color email **blue** (`style="color:blue"`).
   - Color phone **green** (`style="color:green"`).
7. **Separator:** Add `<hr>` between sections.
8. **Save & View** in browser.

---

# Task 2: Treatment Plan Protocol

- **File:** `lists.html`
- **Topic:** Ordered and Unordered Lists
- **Time:** 15 Minutes
- **Objective:** Structure a patient treatment plan using lists.

---

# Task 2: Instructions

1. **Medication Schedule:**
   - Use `<h2>` "Medication Schedule".
   - Create Ordered List `<ol>` (Time matters).
   - **Bold** medication names using `<strong>`.
2. **Dietary Restrictions:**
   - Use `<h2>` "Dietary Restrictions".
   - Create Unordered List `<ul>` (Order doesn't matter).
   - *Italicize* forbidden foods using `<em>`.
3. **Alert:** Make one critical medication **Red** using inline style.

---

# Task 3: Laboratory Results Table

- **File:** `tables.html`
- **Topic:** Tables and Data Structure
- **Time:** 15 Minutes
- **Objective:** Display lab results with visual indicators for pathology.

---

# Task 3: Instructions

1. **Create Table:**
   - Add `<caption>`: "Blood Test Results".
   - Use `<table border="1">`.
2. **Header:**
   - Use `<thead>` and `<th>` for: "Test Name", "Result", "Normal Range".

---

# Task 3: Instructions

3. **Body:**
   - Use `<tbody>` for data rows `<tr>` and `<td>`.
4. **Highlight Pathology:**
   - Choose one abnormal value.
   - Apply style: `style="background-color: #ffcccc; color: red;"`.

---

# Submission & Review

- **Checklist:**
  - [ ] All 3 files saved.
  - [ ] No external CSS used.
  - [ ] Medical terms formatted correctly (sub/sup).
  - [ ] Tables have borders.
  - [ ] Colors applied via inline style.
- **Next Step:** Submit files to the LMS folder.

---

## Info Part 1

```html
<body>
  <!-- Main Heading -->
  <h1>Dr. Ivan Petrov</h1>
  
  <!-- Subheading -->
  <h2>5th Year Medical Student | Cardiology Dept.</h2>
  
  <hr>
  
  <!-- About Section -->
  <h3>About Me</h3>
  <p>
    I am interested in <strong>Emergency Medicine</strong> and 
    internal diseases. I study at <em>State Medical University</em>.
  </p>
```
  
---

## Part 2

```html
  <!-- Medical Formatting -->
  <p>
    Key Metrics: O<sub>2</sub> Saturation, Vitamin B<sub>12</sub>, 
    Body Surface Area: 1.85 m<sup>2</sup>.
  </p>
  
  <!-- Contact Info with Color -->
  <h3>Contact Information</h3>
  <p>
    Email: <span style="color: blue;">ivan.petrov@meduni.edu</span><br>
    Phone: <span style="color: green;">+1-555-0199</span>
  </p>
</body>
```

---

## Lists

```html
<body>
  <!-- Ordered List: Sequence Matters -->
  <h2>Medication Schedule</h2>
  <ol>
    <li>08:00 - <strong>Aspirin 75mg</strong></li>
    <li style="color: red;">12:00 - <strong>Antibiotic (Critical)</strong></li>
    <li>20:00 - <strong>Statin 10mg</strong></li>
  </ol>
  
  <!-- Unordered List: Sequence Does Not Matter -->
  <h2>Dietary Restrictions</h2>
  <ul>
    <li><em>Salty foods</em></li>
    <li><em>Alcohol</em></li>
    <li><em>Fried meat</em></li>
  </ul>
</body>
```

---

## Table Part 1

```html

<body>
  <table border="1">
    <!-- Table Caption -->
    <caption>Blood Test Results</caption>
    
    <!-- Table Header -->
    <thead>
      <tr>
        <th>Test Name</th>
        <th>Patient Result</th>
        <th>Normal Range</th>
      </tr>
    </thead>
```

---

## Part 2

```html

    <!-- Table Body -->
    <tbody>
      <tr>
        <td>Hemoglobin</td>
        <td>140 g/L</td>
        <td>130-160 g/L</td>
      </tr>
      <tr>
        <td>Leukocytes</td>
        <!-- Pathology Highlight -->
        <td style="background-color: #ffcccc; color: red;">
          12.5 x10<sup>9</sup>/L
        </td>
        <td>4.0-9.0 x10<sup>9</sup>/L</td>
      </tr>
    </tbody>
  </table>
</body>
```

---

### HTML5 Tag Cheat Sheet

| Tag | Description | Medical Use Case |
|-----|-------------|------------------|
| `<h1>` - `<h6>` | Headings | Patient Name, Section Titles |
| `<p>` | Paragraph | Descriptions, Notes |
| `<strong>` | Bold Text | Critical Diagnosis |
| `<em>` | Italic Text | Latin terms, Species |
| `<sub>` | Subscript | Chemical formulas (H<sub>2</sub>O) |

---

### HTML5 Tag Cheat Sheet

| Tag | Description | Medical Use Case |
|-----|-------------|------------------|
| `<sup>` | Superscript | Units (m<sup>2</sup>), Powers |
| `<ul>` / `<ol>` | Lists | Symptoms, Medications |
| `<table>` | Table | Lab Results, Schedules |
| `style="..."` | Inline CSS | Color coding alerts |

---

## Common Inline Styles

Do not use external CSS for this lab. Use the style attribute directly in the tag.

```html
<!-- Text Color -->
<span style="color: red;">Error</span>
<span style="color: blue;">Link</span>
<span style="color: green;">Success</span>

<!-- Background Color -->
<div style="background-color: yellow;">Highlight</div>
<td style="background-color: #ffcccc;">Pathology</td>

<!-- Font Weight -->
<p style="font-weight: bold;">Important</p>
```
