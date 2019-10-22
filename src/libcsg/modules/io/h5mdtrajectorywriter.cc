/*
 * Copyright 2009-2019 The VOTCA Development Team (http://www.votca.org)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

#include "h5mdtrajectorywriter.h"
#include "hdf5.h"

namespace votca {
namespace csg {

H5MDTrajectoryWriter::H5MDTrajectoryWriter() {

}

H5MDTrajectoryWriter::~H5MDTrajectoryWriter() {
  if (fileOpened_) {
    H5Fclose(hdfFile_);
    fileOpened_ = false;
  }
}

void csg::H5MDTrajectoryWriter::Open(std::string file, bool bAppend) {
  if (!H5Fis_hdf5(file.c_str())) {
    std::cout << file << " is not recognise as HDF5 file format" << std::endl;
    return;
  }

  appendMode = bAppend;

  if (bAppend) {
    hdfFile_ = H5Fopen(file.c_str(), H5F_ACC_CREAT, H5P_DEFAULT);
  } else {
    hdfFile_ = H5Fopen(file.c_str(), H5F_ACC_TRUNC, H5P_DEFAULT);
  }
  fileOpened_ = true;

}

void H5MDTrajectoryWriter::Close() {
  if (fileOpened_) {
    H5Fclose(hdfFile_);
    fileOpened_ = false;
  }
}

void H5MDTrajectoryWriter::Write(Topology *conf) {

}

void H5MDTrajectoryWriter::Initialize(Topology *top) {
  std::string particle_group_name_ = top->getParticleGroup();
  if (particle_group_name_.compare(UnassignedParticleGroupName) == 0) {
    particle_group_name_ = "atoms";
  }

  std::string position_group_name = particle_group_name_ + "/position";
  if (!GroupExists(hdfFile_, position_group_name) && )
  atom_position_group_ =
      H5Gopen(particle_group_, position_group_name.c_str(), H5P_DEFAULT);
}

}  // namespace csg
}  // namespace votca