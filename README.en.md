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

The implementation supports both **2D** and **3D** optimization problems, with modular code structure for easy extension.

---

### 🎯 Key Features

- **No sensitivity calculation required**: Eliminates complex sensitivity analysis, simplifying implementation
- **Numerical stability**: Proportional material distribution ensures stable and reliable convergence
- **Easy to implement**: Clear, modular code structure, easy to customize and extend
- **Efficient for medium-scale models**: Optimized for problems of moderate size
- **Versatile problem support**: Includes multiple benchmark structural mechanics problems
- **2D and 3D support**: Complete implementation for both 2D plane stress and 3D solid mechanics
- **STL export**: Export optimized 3D designs to STL format for CAD/CAM integration
- **Comprehensive boundary conditions**: Library of common structural mechanics problems

---

### ⚠️ Important Notice

**This is a research-oriented implementation of the PTO algorithm.**  
Results may vary depending on problem settings and parameter choices. Always verify and validate results before applying them to real-world engineering designs.

---

## 🚀 Quick Start

### System Requirements

- **MATLAB**: Version R2021b or later
- **Toolboxes**: No special toolbox required
- **Hardware**: Sufficient RAM for stiffness matrices (approximately 2–4 GB for a 100×50 element 2D problem, 8–16 GB for 30×30×30 3D problem)

---

### Installation

1. Clone the repository:
```bash
git clone https://gitlab.com/phn1712002/proportional_topology_optimization.git
cd proportional_topology_optimization/code_ws
```

2. Add all folders to the MATLAB path:

```matlab
add_lib(pwd);
```

---

### Running Example Problems

The project provides simulation scripts for common structural mechanics benchmark problems in both 2D and 3D:

#### 2D Problems
```matlab
% 1. Cantilever beam (2D)
simulate_cantilever_beam_PTOc;    % Using PTOc
simulate_cantilever_beam_PTOs;    % Using PTOs

% 2. MBB beam (Michell-type structure, 2D)
simulate_mbb_beam_PTOc;           % Using PTOc
simulate_mbb_beam_PTOs;           % Using PTOs

% 3. L-bracket (2D)
simulate_Lbracket_PTOc;           % Using PTOc
simulate_Lbracket_PTOs;           % Using PTOs

% 4. General 2D problems
simulate_PTOc;                    % Generic PTOc with custom parameters
simulate_PTOs;                    % Generic PTOs with custom parameters
```

#### 3D Problems
```matlab
% 1. 3D Cantilever beam
simulate_3d_PTOc;                 % 3D PTOc optimization
simulate_3d_PTOs;                 % 3D PTOs optimization

% 2. 3D Plate with hole
simulate_plate_3d_PTOc;           % 3D plate optimization with PTOc
simulate_plate_3d_PTOs;           % 3D plate optimization with PTOs
```

Each script automatically runs the optimization and visualizes results through animations, convergence plots, and the final density distribution. 3D results can be exported to STL format for further analysis.

---

## 📁 Project Structure

```
.
├── README.md                          # Documentation (Vietnamese)
├── README.en.md                       # Documentation (English)
├── LICENSE                           # MIT License
├── add_lib.m                         # Add all subfolders to MATLAB path
├── simulate_*.m                      # Simulation scripts (14 files)
│
├── boundary_conditions/              # Boundary condition library
│   ├── cantilever_beam_boundary.m    # Cantilever beam (2D)
│   ├── l_bracket_boundary.m          # L-bracket (2D)
│   ├── l_bracket_3d_boundary.m       # L-bracket (3D)
│   ├── mbb_beam_boundary.m           # MBB beam (2D)
│   ├── plate_3d_boundary.m           # Plate with hole (3D)
│   ├── fixed_fixed_beam_boundary.m   # Fixed-fixed beam (2D)
│   ├── simply_supported_beam_boundary.m # Simply supported beam (2D)
│   ├── multiple_supports_boundary.m  # Multiple supports (2D)
│   ├── distributed_load_example.m    # Distributed load example (2D)
│   ├── visualize_boundary_conditions.m    # 2D visualization
│   └── visualize_boundary_conditions_3d.m # 3D visualization
│
├── core/                             # Core algorithm library
│   ├── 2D Functions:
│   │   ├── FEA_analysis.m                # Finite Element Analysis (2D)
│   │   ├── compute_compliance.m          # Compliance computation (2D)
│   │   ├── compute_stress.m              # Von Mises stress calculation (2D)
│   │   ├── density_filter.m              # Density filter (2D, cone kernel)
│   │   ├── material_distribution_PTOc.m  # Material distribution for PTOc (2D)
│   │   ├── material_distribution_PTOs.m  # Material distribution for PTOs (2D)
│   │   ├── run_ptoc_iteration.m          # PTOc optimization loop (2D)
│   │   ├── run_ptos_iteration.m          # PTOs optimization loop (2D)
│   │   ├── assemble_global_stiffness.m   # Global stiffness assembly (2D)
│   │   ├── element_stiffness_matrix.m    # Element stiffness matrix (2D)
│   │   └── strain_displacement_matrix_centroid.m # Strain-displacement matrix (2D)
│   │
│   ├── 3D Functions:
│   │   ├── FEA_analysis_3d.m                # Finite Element Analysis (3D)
│   │   ├── compute_compliance_3d.m          # Compliance computation (3D)
│   │   ├── compute_stress_3d.m              # Von Mises stress calculation (3D)
│   │   ├── density_filter_3d.m              # Density filter (3D)
│   │   ├── material_distribution_PTOc_3d.m  # Material distribution for PTOc (3D)
│   │   ├── material_distribution_PTOs_3d.m  # Material distribution for PTOs (3D)
│   │   ├── run_ptoc_iteration_3d.m          # PTOc optimization loop (3D)
│   │   ├── run_ptos_iteration_3d.m          # PTOs optimization loop (3D)
│   │   ├── assemble_global_stiffness_3d.m   # Global stiffness assembly (3D)
│   │   ├── element_stiffness_matrix_3d_hex8.m # Element stiffness matrix (3D, HEX8)
│   │   └── strain_displacement_matrix_centroid_3d_hex8.m # Strain-displacement matrix (3D)
│   │
│   ├── Common Functions:
│   │   ├── update_density.m              # Density update with move limit
│   │   ├── check_convergence.m           # Convergence check
│   │   ├── export_density_to_stl_3d.m    # Export 3D density to STL format
│   │   └── export_optimization_results_3d.m # Export 3D optimization results
│
├── lib/                              # External libraries
│   └── stlTools/                     # STL file I/O utilities
│       ├── stlRead.m                 # Read STL files
│       ├── stlWrite.m                # Write STL files
│       ├── stlPlot.m                 # Visualize STL files
│       └── ... (additional STL tools)
│
├── docs/                             # Detailed algorithm documentation
│   ├── docs-ptoc.md                  # Full PTOc documentation
│   └── docs-ptos.md                  # Full PTOs documentation
│
├── rules/                            # Project development rules
│   ├── create-flowchart.md           # Flowchart creation guidelines
│   ├── matlab-coding.md              # MATLAB coding standards
│   └── boundary-condition-guidelines.md # Boundary condition guidelines
│
├── test/                             # Test scripts and validation
└── results/                          # Output directory for optimization results
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
   * (3D only) STL export capability

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
   * (3D only) STL export capability

---

## 📊 Tunable Parameters

| Parameter         | PTOc | PTOs | Description                   | Recommended Value (2D) | Recommended Value (3D) |
| ----------------- | ---- | ---- | ----------------------------- | ---------------------- | ---------------------- |
| `q`               | ✓    | ✓    | Proportional exponent         | 1.0 – 2.0              | 1.0 – 2.0              |
| `r_min`           | ✓    | ✓    | Density filter radius         | 1.25 – 2.0             | 1.5 – 2.5              |
| `alpha`           | ✓    | ✓    | History factor (move limit)   | 0.3 – 0.5              | 0.3 – 0.5              |
| `volume_fraction` | ✓    | -    | Volume fraction (PTOc)        | 0.3 – 0.5              | 0.2 – 0.4              |
| `sigma_allow`     | -    | ✓    | Allowable stress (PTOs)       | 0.8 – 1.2              | 0.8 – 1.2              |
| `tau`             | -    | ✓    | Stress tolerance band         | 0.05 – 0.1             | 0.05 – 0.1             |
| `max_iter`        | ✓    | ✓    | Maximum iterations            | 200 – 500              | 100 – 300              |
| `conv_tol`        | ✓    | ✓    | Density convergence tolerance | 1e-4                   | 1e-3                   |
| `p`               | ✓    | ✓    | SIMP penalization factor      | 3.0                    | 3.0                    |
| `nelx, nely`      | ✓    | ✓    | Mesh dimensions (2D)          | 60–200                 | -                      |
| `nelx, nely, nelz`| ✓    | ✓    | Mesh dimensions (3D)          | -                      | 20–50                  |

**Note**: 3D problems require more conservative parameters due to increased computational cost and memory requirements.

---

## 🎮 Advanced Usage

### Creating a New Optimization Problem

1. **Create a new boundary condition file** in `boundary_conditions/`:

```matlab
function [fixed_dofs, load_dofs, load_vals, nelx, nely] = new_problem_boundary(plot_flag)
% NEW_PROBLEM_BOUNDARY Boundary conditions for new problem
%
% Input:
%   plot_flag - Boolean: true to visualize boundary conditions
%
% Output:
%   fixed_dofs - Degrees of freedom with fixed displacement
%   load_dofs  - DOFs where loads are applied
%   load_vals  - Corresponding load values
%   nelx, nely - Mesh dimensions
```

For 3D problems:
```matlab
function [fixed_dofs, load_dofs, load_vals, nelx, nely, nelz] = new_3d_problem_boundary(plot_flag)
```

2. **Create a new simulation script** based on `simulate_*.m`.

### Exporting 3D Results to STL

Optimized 3D designs can be exported to STL format for CAD/CAM integration:

```matlab
% After running 3D optimization
rho_opt_3d = ...; % Your 3D density matrix

% Export to STL
export_density_to_stl_3d(rho_opt_3d, 0.5, 'optimized_design.stl');
% 0.5 is the isosurface threshold (adjust based on density distribution)
```

### Performance Considerations for 3D Problems

- **Memory**: 3D stiffness matrices grow rapidly. A 30×30×30 mesh requires ~2GB RAM
- **Computation time**: 3D FEA is significantly slower. Use smaller meshes for testing
- **Convergence**: 3D problems may require more iterations and different parameters

---

## 🔍 Debugging & Troubleshooting

### Common Issues

1. **Singular stiffness matrices in FEA**:
   - Check `E_min = 1e-9 * E0` in `FEA_analysis.m` or `FEA_analysis_3d.m`
   - Ensure `rho_min > 0` to avoid zero-stiffness elements
   - Verify boundary conditions are properly applied

2. **Lack of convergence**:
   - Reduce `alpha` (e.g., from 0.5 to 0.3)
   - Increase `max_iter`
   - Check and adjust parameters `q`, `r_min`
   - Verify convergence tolerance `conv_tol` is appropriate

3. **Checkerboard patterns or non-smooth results**:
   - Increase filter radius `r_min` (e.g., from 1.25 to 2.0)
   - Check filter effectiveness in `density_filter.m` or `density_filter_3d.m`
   - Consider using sensitivity filtering instead of density filtering

4. **Stress violations in PTOs**:
   - Adjust `sigma_allow` and `tau` appropriately
   - Check `TM` adjustment method in `run_ptos_iteration.m` or `run_ptos_iteration_3d.m`
   - Verify Von Mises stress calculation accuracy

5. **Memory issues with 3D problems**:
   - Reduce mesh size (`nelx`, `nely`, `nelz`)
   - Use sparse matrices effectively (already implemented)
   - Close unnecessary MATLAB figures and variables
   - Consider running on a machine with more RAM

### Debugging Tools

- **`visualize_boundary_conditions.m` / `visualize_boundary_conditions_3d.m`**: Visualize boundary conditions to verify setup
- **Convergence history**: Variables `history` in `run_ptoc_iteration.m` and `run_ptos_iteration.m` provide data for convergence analysis
- **Automatic figures**: Generated during execution help monitor progress
- **Step-by-step testing**: Run individual functions to verify outputs

---

## 📚 Original Research Paper

**Biyikli, E., & To, A. C. (2015).**
*Proportional Topology Optimization: A New Non-Sensitivity Method for Solving Stress Constrained and Minimum Compliance Problems and Its Implementation in MATLAB.*
PLoS ONE, 10(12), e0145041, https://doi.org/10.1371/journal.pone.0145041.

### Acknowledgments

We extend sincere thanks to the authors **Emre Biyikli** and **Albert C. To** for developing and publishing the Proportional Topology Optimization method.

---

## 📄 License

This project is distributed under the **MIT License**. See the `LICENSE` file for full details.

**MIT License Summary**:
- Permission is granted to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the software
- The copyright notice and permission notice must be included in all copies or substantial portions of the software
- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND

---

## 📞 Contact

* **Author**: Pham Hoang Nam
* **Email**: [phn1712002@gmail.com](mailto:phn1712002@gmail.com)
