#
# Copyright (C) 2013,2014,2015,2016 The ESPResSo project
#
# This file is part of ESPResSo.
#
# ESPResSo is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ESPResSo is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
from __future__ import print_function, absolute_import
from . cimport cellsystem
from . cimport integrate
from globals cimport *
import numpy as np
from espressomd.utils cimport handle_errors

cdef class CellSystem(object):
    def set_domain_decomposition(self, use_verlet_lists=True):
        """Activates domain decomposition cell system
        set_domain_decomposition(useVerletList=True)
        """
        if use_verlet_lists:
            dd.use_vList = 1
        else:
            dd.use_vList = 0

        # grid.h::node_grid
        mpi_bcast_cell_structure(CELL_STRUCTURE_DOMDEC)

        # @TODO: gathering should be interface independent
        # return mpi_gather_runtime_errors(interp, TCL_OK)
        return True

    def set_n_square(self, use_verlet_lists=True):
        """Activates the nsquare force calculation
        """
        if use_verlet_lists:
            dd.use_vList = 1
        else:
            dd.use_vList = 0
        mpi_bcast_cell_structure(CELL_STRUCTURE_NSQUARE)
        # @TODO: gathering should be interface independent
        # return mpi_gather_runtime_errors(interp, TCL_OK)
        return True

    def set_layered(self, n_layers=None):
        """set_layered(n_layers=None)
        Set the layerd cell system with n_layers layers"""
        if n_layers:
            if not isinstance(n_layers, int):
                raise ValueError("layer height should be positive")

            if not n_layers > 0:
                raise ValueError("the number of layers has to be >0")

            global n_layers_
            n_layers_ = int(n_layers)
            global determine_n_layers
            determine_n_layers = 0

        if (node_grid[0] != 1 or node_grid[1] != 1):
            node_grid[0] = node_grid[1] = 1
            node_grid[2] = n_nodes
            mpi_err = mpi_bcast_parameter(FIELD_NODEGRID)
            handle_errors("mpi_bcast_parameter failed")
        else:
            mpi_err = 0

        if not mpi_err:
            mpi_bcast_cell_structure(CELL_STRUCTURE_LAYERED)

        # @TODO: gathering should be interface independent
        # return mpi_gather_runtime_errors(interp, TCL_OK)

        if mpi_err:
            raise Exception("Broadcasting the node grid failed")
        return True

    def get_state(self):
        s = {}
        if cell_structure.type == CELL_STRUCTURE_LAYERED:
            s["type"] = "layered"
            s["n_layers"] = n_layers
        if cell_structure.type == CELL_STRUCTURE_DOMDEC:
            s["type"] = "domain_decomposition"
            s["use_verlet_lists"] = dd.use_vList
        if cell_structure.type == CELL_STRUCTURE_NSQUARE:
            s["type"] = "nsquare"
            s["use_verlet_lists"] = dd.use_vList


        s["skin"] = skin
        s["local_box_l"] = np.array([local_box_l[0], local_box_l[1], local_box_l[2]])
        s["max_cut"] = max_cut
        s["max_range"] = max_range
        s["max_skin"] = max_skin
        s["n_layers"] = n_layers_
        s["verlet_reuse"] = verlet_reuse
        s["n_nodes"] = n_nodes
        s["node_grid"] = np.array([node_grid[0], node_grid[1], node_grid[2]])
        s["cell_grid"] = np.array([dd.cell_grid[0], dd.cell_grid[1], dd.cell_grid[2]])
        s["cell_size"] = np.array([dd.cell_size[0], dd.cell_size[1], dd.cell_size[2]])
        s["max_num_cells"] = max_num_cells
        s["min_num_cells"] = min_num_cells

        return s


    property max_num_cells:
        def __set__(self, int _max_num_cells):
            global max_num_cells
            if _max_num_cells < min_num_cells:
                raise ValueError(
                    "max_num_cells must be >= min_num_cells (currently " + str(min_num_cells) + ")")
            max_num_cells = _max_num_cells
            mpi_bcast_parameter(FIELD_MAXNUMCELLS)

        def __get__(self):
            return max_num_cells

    property min_num_cells:
        def __set__(self, int _min_num_cells):
            global min_num_cells
            min = calc_processor_min_num_cells()
            if _min_num_cells < min:
                raise ValueError(
                    "min_num_cells must be >= processor_min_num_cells (currently " + str(min) + ")")
            if _min_num_cells > max_num_cells:
                raise ValueError(
                    "min_num_cells must be <= max_num_cells (currently " + str(max_num_cells) + ")")
            min_num_cells = _min_num_cells
            mpi_bcast_parameter(FIELD_MINNUMCELLS)

        def __get__(self):
            return min_num_cells


    # setter deprecated
    property node_grid:
        def __set__(self, _node_grid):
            raise Exception('node_grid is not settable by the user.')

        def __get__(self):
            return np.array([node_grid[0], node_grid[1], node_grid[2]])


    property skin:
        def __set__(self, double _skin):
            if _skin < 0:
                raise ValueError("Skin must be >= 0")
            global skin
            skin = _skin
            mpi_bcast_parameter(29)
            integrate.skin_set = True

        def __get__(self):
            return skin


