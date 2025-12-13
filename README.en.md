# Proportional Topology Optimization (PTO)

<p align="center">
  VN <a href="README.md">Tiếng Việt</a> |
  US <a href="README.en.md">English</a> |
</p>

[![MATLAB](https://img.shields.io/badge/MATLAB-R2021b%2B-blue.svg)](https://www.mathworks.com/products/matlab.html)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📋 Overview

**Proportional Topology Optimization (PTO)** is a non-sensitivity-based method for structural topology optimization problems in solid mechanics. This approach provides a simple, stable, and easy-to-implement alternative compared to traditional sensitivity-based methods.

This project implements two main variants of the PTO algorithm:

- **PTOc (Proportional Topology Optimization for compliance)**: Minimizes structural compliance under a fixed volume constraint.
- **PTOs (Proportional Topology Optimization for stress constraints)**: Minimizes material volume subject to allowable stress constraints.

---

### 🎯 Key Features

- **No sensitivity calculation required**: Eliminates complex sensitivity analysis, simplifying implementation
- **Numerical stability**: Proportional material distribution ensures stable and reliable convergence
- **Easy to implement**: Clear, modular code structure, easy to customize and extend
- **Efficient for medium-scale models**: Optimized for problems of moderate size
- **Versatile problem support**: Includes multiple benchmark structural mechanics problems

---

### ⚠️ Important Notice

**This is a research-oriented implementation of the PTO algorithm.**  
Results may vary depending on problem settings and parameter choices. Always verify and validate results before applying them to real-world engineering designs.

---

## 🚀 Quick Start

### System Requirements

- **MATLAB**: Version R2021b or later
- **Toolboxes**: No special toolbox required
- **Hardware**: Sufficient RAM for stiffness matrices (approximately 2–4 GB for a 100×50 element problem)

---

### Installation

1. Clone the repository:
```bash
git clone https://gitlab.com/phn1712002/proportional_topology_optimization.git
cd proportional_topology_optimization/code_ws
````

2. Add all folders to the MATLAB path:

```matlab
add_lib(pwd);
```

---

### Running Example Problems

The project provides six simulation scripts for common structural mechanics benchmark problems:

```matlab
% 1. Cantilever beam
simulate_cantilever_beam_PTOc;    % Using PTOc
simulate_cantilever_beam_PTOs;    % Using PTOs

% 2. MBB beam (Michell-type structure)
simulate_mbb_beam_PTOc;           % Using PTOc
simulate_mbb_beam_PTOs;           % Using PTOs

% 3. L-bracket
simulate_Lbracket_PTOc;           % Using PTOc
simulate_Lbracket_PTOs;           % Using PTOs
```

Each script automatically runs the optimization and visualizes results through animations, convergence plots, and the final density distribution.

---

## 📁 Project Structure

```
.
├── README.md                          # Documentation (you are reading this)
├── LICENSE                           # MIT License
├── add_lib.m                         # Add all subfolders to MATLAB path
├── simulate_*.m                      # Simulation scripts (6 files)
│
├── boundary_conditions/              # Boundary condition library
│   ├── cantilever_beam_boundary.m
│   ├── l_bracket_boundary.m
│   ├── mbb_beam_boundary.m
│   └── visualize_boundary_conditions.m
│
├── core/                             # Core algorithm library
│   ├── FEA_analysis.m                # Finite Element Analysis
│   ├── compute_compliance.m          # Compliance computation
│   ├── compute_stress.m              # Von Mises stress calculation
│   ├── density_filter.m              # Density filter (cone kernel)
│   ├── material_distribution_PTOc.m  # Material distribution for PTOc
│   ├── material_distribution_PTOs.m  # Material distribution for PTOs
│   ├── run_ptoc_iteration.m          # PTOc optimization loop
│   ├── run_ptos_iteration.m          # PTOs optimization loop
│   ├── update_density.m              # Density update with move limit
│   └── check_convergence.m           # Convergence check
│
├── docs/                             # Detailed algorithm documentation
│   ├── docs-ptoc.md                  # Full PTOc documentation
│   └── docs-ptos.md                  # Full PTOs documentation
│
└── rules/                            # Project development rules
    ├── create-flowchart.md
    ├── matlab-coding.md
    └── general_rules.md
```

---

## 🔧 Algorithm Details

### PTOc – Compliance Minimization

**Objective**
Minimize the **compliance**:

```
C = Uᵀ · K · U
```

where:

* `U` : displacement vector
* `K` : global stiffness matrix

subject to a **fixed volume constraint**.

---

**Workflow**

1. **Initialization**
   Uniform initial material density:

```
density = volume_fraction
```

2. **Main optimization loop** (until convergence)

   * Perform FEA to compute:

     ```
     U  (displacement)
     K  (stiffness matrix)
     ```

   * Compute **element compliance**:

     ```
     Ce = Ueᵀ · Ke · Ue
     ```

   * **Material distribution** proportional to compliance:

     ```
     density ∝ Ce^q
     ```

     (`q` controls material concentration)

   * **Density filtering** with radius:

     ```
     r_min
     ```

   * **Density update** with history factor (move limit):

     ```
     density_new = alpha · density_old + (1 - alpha) · density_update
     ```

   * **Convergence check** based on:

     ```
     max(|density_new - density_old|)
     ```

3. **Output**

   * Optimized density distribution
   * Convergence history

---

### PTOs – Stress-Constrained Optimization

**Objective**
Minimize **material volume** subject to:

```
sigma_vm ≤ sigma_allow
```

where:

* `sigma_vm` : Von Mises stress
* `sigma_allow` : allowable stress

---

**Workflow**

1. **Initialization**

   * Initial density distribution
   * Target material amount:

     ```
     TM
     ```

2. **Main optimization loop** (until convergence)

   * Perform FEA and compute:

     ```
     sigma_vm
     ```

   * Compare maximum stress:

     ```
     sigma_max vs sigma_allow
     ```

   * **Adjust target material**:

     ```
     if sigma_max > sigma_allow → increase TM
     if sigma_max < sigma_allow → decrease TM
     ```

   * **Material distribution based on stress**:

     ```
     density ∝ sigma_vm^q
     ```

   * **Filtering and update** (same as PTOc):

     ```
     density_new = alpha · density_old + (1 - alpha) · density_update
     ```

   * **Convergence check** based on:

     ```
     |sigma_max - sigma_allow|
     and
     max(|density_new - density_old|)
     ```

3. **Output**

   * Optimized density distribution
   * Stress constraint satisfaction

---

## 📊 Tunable Parameters

| Parameter         | PTOc | PTOs | Description                   | Recommended Value |
| ----------------- | ---- | ---- | ----------------------------- | ----------------- |
| `q`               | ✓    | ✓    | Proportional exponent         | 1.0 – 2.0         |
| `r_min`           | ✓    | ✓    | Density filter radius         | 1.25 – 2.0        |
| `alpha`           | ✓    | ✓    | History factor (move limit)   | 0.3 – 0.5         |
| `volume_fraction` | ✓    | -    | Volume fraction (PTOc)        | 0.3 – 0.5         |
| `sigma_allow`     | -    | ✓    | Allowable stress (PTOs)       | 0.8 – 1.2         |
| `tau`             | -    | ✓    | Stress tolerance band         | 0.05 – 0.1        |
| `max_iter`        | ✓    | ✓    | Maximum iterations            | 200 – 500         |
| `conv_tol`        | ✓    | ✓    | Density convergence tolerance | 1e-4              |
| `p`               | ✓    | ✓    | SIMP penalization factor      | 3.0               |

---

## 🎮 Advanced Usage

### Creating a New Optimization Problem

1. **Create a new boundary condition file** in `boundary_conditions/`:

```matlab
function [fixed_dofs, load_dofs, load_vals, nelx, nely] = new_problem_boundary(plot_flag)
```

2. **Create a new simulation script** based on `simulate_*.m`.

---

## 🔍 Debugging & Troubleshooting

Common issues include singular stiffness matrices, lack of convergence, checkerboard patterns, and stress violations. Refer to the detailed notes in the code and documentation for parameter tuning and debugging tools.

---

## 📚 Original Research Paper

**Biyikli, E., & To, A. C. (2015).**
*Proportional Topology Optimization: A New Non-Sensitivity Method for Solving Stress Constrained and Minimum Compliance Problems and Its Implementation in MATLAB.*
PLoS ONE, 10(12), e0145041, https://doi.org/10.1371/journal.pone.0145041.

---

## 📄 License

This project is distributed under the **MIT License**. See the `LICENSE` file for details.

---

## 📞 Contact

* **Author**: Pham Hoang Nam
* **Email**: [phn1712002@gmail.com](mailto:phn1712002@gmail.com)

