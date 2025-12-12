# Proportional Topology Optimization (PTO) - Project Documentation

## 📋 Overview

This project implements **Proportional Topology Optimization (PTO)** algorithms in MATLAB, featuring two variants:

1. **PTOs** – Stress-constrained topology optimization
2. **PTOc** – Minimum compliance topology optimization

The implementation follows the SIMP (Solid Isotropic Material with Penalization) method with density filtering to prevent checkerboarding. The code is modular, well-documented, and includes benchmark examples for validation.

---

## 🏗️ Project Structure

```
.
├── add_lib.m                   # Utility to add all subfolders to MATLAB path
├── run_all_simulations.m       # Master script to run all simulations
├── run_benchmarks.m            # Benchmark comparison script
├── simulate_*.m                # Individual simulation scripts (6 files)
├── general_rules.md            # This documentation file
├── test_implementation.m       # Testing
└── core/                       # Core algorithm modules
    ├── FEA_analysis.m          # Finite element analysis
    ├── compute_stress.m        # Von Mises stress computation
    ├── compute_compliance.m    # Element compliance computation
    ├── density_filter.m        # Cone-shaped density filter
    ├── material_distribution_PTOs.m  # Material distribution for PTOs
    ├── material_distribution_PTOc.m  # Material distribution for PTOc
    ├── update_density.m        # Density update with move limit
    ├── check_convergence.m     # Convergence checking
    ├── PTOs_main.m            # Main PTOs algorithm
    └── PTOc_main.m            # Main PTOc algorithm
```

---

## 🚀 Getting Started

### 1. Setup MATLAB Environment

```matlab
% Run from the project root directory
add_lib(pwd);  % Adds all subfolders to MATLAB path
```

### 2. Quick Start Example

```matlab
% Run a simple cantilever beam optimization (PTOc)
nelx = 60; nely = 30;
p = 3; q = 1.0; r_min = 1.5; alpha = 0.3;
volume_fraction = 0.4; max_iter = 100;

[rho_opt, history] = PTOc_main(nelx, nely, p, q, r_min, alpha, ...
                                volume_fraction, max_iter, true);
```

### 3. Running Simulations

Three benchmark problems are provided:

| Problem | Mesh Size | Description |
|---------|-----------|-------------|
| MBB Beam | 120×40 | Half-symmetry beam with roller support |
| Cantilever Beam | 120×60 | Fixed left edge, load at right middle |
| L-bracket | 100×40 | Rectangular domain with cutout |

Run individual simulations:
```matlab
simulate_MBB_PTOs;    % MBB beam with stress constraint
simulate_MBB_PTOc;    % MBB beam with compliance minimization
simulate_Cantilever_PTOs;
simulate_Cantilever_PTOc;
simulate_Lbracket_PTOs;
simulate_Lbracket_PTOc;
```

### 4. Comprehensive Run

```matlab
run_all_simulations;  % Runs all 6 cases with quick mode (50 iterations)
% Set quick_run = false in the script for full simulations (300 iterations)
```

---

## 🔧 Algorithm Details

### PTOs (Stress-constrained)

1. **Initialization**: Uniform density, set target material (TM)
2. **FEA Analysis**: Solve KU = F with SIMP interpolation
3. **Stress Computation**: Von Mises stress per element
4. **TM Adjustment**: 
   - If max stress > (1+τ)·σ_allow: increase TM
   - If max stress < (1-τ)·σ_allow: decrease TM
5. **Material Redistribution**: Distribute remaining material (RM) proportionally to stress^q
6. **Density Filtering**: Apply cone-shaped filter (radius r_min)
7. **Density Update**: ρ_new = α·ρ_prev + (1-α)·ρ_opt
8. **Convergence Check**: Stop when stress within tolerance and density change small

### PTOc (Minimum Compliance)

1. **Initialization**: Uniform density, fixed TM = volume_fraction × total elements
2. **FEA Analysis**: Solve KU = F
3. **Compliance Computation**: Element compliance C_i = U_i^T K_i U_i
4. **Material Redistribution**: Distribute RM proportionally to C_i^q
5. **Density Filtering**: Same as PTOs
6. **Density Update**: Same as PTOs
7. **Convergence Check**: Stop when max|ρ_new - ρ_prev| < tolerance

---

## ⚙️ Key Parameters

| Parameter | Symbol | Typical Value | Description |
|-----------|--------|---------------|-------------|
| SIMP penalty | p | 3.0 | Penalizes intermediate densities |
| Proportionality exponent | q | 1.0 | Sensitivity of distribution to stress/compliance |
| Filter radius | r_min | 1.5-2.0 | Radius of density filter (element units) |
| Move limit | α | 0.2-0.5 | Controls density change per iteration |
| Allowable stress | σ_allow | 80-120 | Maximum allowed von Mises stress (PTOs only) |
| Stress tolerance | τ | 0.05 | Band around σ_allow for convergence (PTOs only) |
| Volume fraction | V_f | 0.3-0.5 | Target material volume (PTOc only) |
| Max iterations | - | 200-300 | Maximum optimization iterations |

---

## 📊 Output and Visualization

Each simulation generates:

1. **MAT Files**: Contains `rho_opt` (final density), `history` (iteration data)
2. **PNG Figures**: 
   - Final topology design
   - Stress/compliance distribution
   - Convergence history plots
   - Volume and parameter evolution

Example output files:
- `MBB_PTOs_results.mat` / `MBB_PTOs_results.png`
- `Cantilever_PTOc_results.mat` / `Cantilever_PTOc_results.png`
- `PTO_simulation_results.mat` / `PTO_comparison_report.png`

---

## 🔍 Code Quality and Standards

### Naming Conventions
- **Functions**: `snake_case` (e.g., `compute_stress`)
- **Variables**: `snake_case` (e.g., `sigma_vm`)
- **Constants**: `UPPER_SNAKE_CASE` (defined within functions)

### Documentation
- Each function includes a help block with description, inputs, outputs, and examples
- Inline comments explain complex operations
- TODO/FIXME comments mark areas for improvement

### Modular Design
- Each module has a single responsibility
- Functions are short (< 100 lines)
- Clear separation between FEA, optimization, and visualization

---

## 🧪 Testing and Validation

### Unit Tests
Run the test suite:
```matlab
test_implementation;  % Tests all core modules
```

### Benchmark Validation
Compare with standard topology optimization results:
- MBB beam should show characteristic truss-like structure
- Cantilever beam should exhibit diagonal support members
- L-bracket should avoid stress concentrations at re-entrant corner

### Numerical Checks
- Volume conservation after filtering
- Stress values within reasonable bounds
- Monotonic convergence (for PTOc)

---

## 🔄 Extending the Project

### Adding New Problems
1. Create a new simulation script following the pattern of `simulate_*.m`
2. Define mesh dimensions (`nelx`, `nely`)
3. Set boundary conditions (`fixed_dofs`, `load_dofs`)
4. Choose algorithm parameters (`p`, `q`, `r_min`, etc.)
5. Call `PTOs_main` or `PTOc_main`

### Modifying Algorithms
1. **New Material Model**: Modify `FEA_analysis.m` and `compute_stress.m`
2. **Different Filter**: Replace `density_filter.m` with alternative implementation
3. **Advanced Convergence Criteria**: Extend `check_convergence.m`
4. **Parallel Computation**: Add parallel loops in FEA assembly

### Adding Features
1. **Sensitivity Analysis**: Vary `q` and `α` to study parameter influence
2. **Multi-load Cases**: Extend load vector `F` to multiple load cases
3. **Passive Elements**: Modify initial density to include fixed voids/solids
4. **3D Extension**: Adapt element stiffness matrices and filtering for 3D

---

## ⚠️ Common Issues and Troubleshooting

### 1. Singular Stiffness Matrix
- **Cause**: Density too low (near zero) causing near-zero Young's modulus
- **Fix**: Ensure `E_min = 1e-9 * E0` in SIMP interpolation

### 2. Checkerboard Patterns
- **Cause**: Insufficient filtering
- **Fix**: Increase `r_min` or use more aggressive filtering

### 3. Slow Convergence
- **Cause**: Move limit `α` too high
- **Fix**: Reduce `α` to 0.2-0.3 for faster changes

### 4. Unrealistic Stress Values
- **Cause**: Poor mesh resolution near stress concentrations
- **Fix**: Refine mesh or use adaptive refinement

### 5. Memory Issues
- **Cause**: Large mesh sizes (>200×100)
- **Fix**: Use sparse matrices, reduce max iterations, or use coarser mesh

---

## 📚 References

1. **Original PTO Algorithm**: 
   - Proportional Topology Optimization (PTO) for stress-constrained and compliance minimization problems
   
2. **SIMP Method**:
   - Bendsoe, M. P., & Sigmund, O. (2003). Topology Optimization: Theory, Methods, and Applications.
   
3. **Density Filtering**:
   - Bourdin, B. (2001). Filters in topology optimization.

4. **MATLAB FEA Implementation**:
   - Andreassen, E., et al. (2011). Efficient topology optimization in MATLAB using 88 lines of code.

---

## 👥 Contributing

1. Fork the repository
2. Create a feature branch
3. Follow existing coding standards
4. Add tests for new functionality
5. Update documentation
6. Submit a pull request

---

## 📄 License

This project is for academic and research use. Please cite appropriately if used in publications.

---

## 🆘 Support

For questions or issues:
1. Check this documentation
2. Examine example scripts
3. Review MATLAB error messages
4. Contact the development team

---

*Last Updated: December 2025*  
*Project Status: Production Ready*
