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

#include <boost/filesystem/operations.hpp>
#include "h5mdtrajectorywriter.h"
#include "H5Cpp.h"

namespace votca {
namespace csg {

H5MDTrajectoryWriter::H5MDTrajectoryWriter() {

}

H5MDTrajectoryWriter::~H5MDTrajectoryWriter() {
}

void csg::H5MDTrajectoryWriter::Open(std::string fileName, bool bAppend) {
  // disbale default HDF5-Diag messags
  H5::Exception::dontPrint();

  appendMode = bAppend;

  if (!H5::H5File::isHdf5(fileName)) {
    // wrong file format
    throw std::ios_base::failure("Wrong file format");
  }


  if (!boost::filesystem::exists(fileName)) {
    hdfFile_ = H5::H5File(fileName, H5F_ACC_EXCL);
    newFile_ = true;
  } else {
    hdfFile_ = H5::H5File(fileName, H5F_ACC_RDWR);
    newFile_ = false;
  }

  fileOpened_ = true;
}

void H5MDTrajectoryWriter::Close() {
}

void H5MDTrajectoryWriter::Write(Topology *conf) {

}

void H5MDTrajectoryWriter::Initialize(Topology *top) {
  std::string particle_group_name_ = top->getParticleGroup();
  if (particle_group_name_.compare(UnassignedParticleGroupName) == 0) {
    particle_group_name_ = "atoms";
  }

  if (newFile_) {
    initializeHeader();
  }

  particleGroup_ = hdfFile_.openGroup(std::string("/particles/") + particle_group_name_);
}


void H5MDTrajectoryWriter::initializeHeader() {
  const H5::Group &h5md = hdfFile_.createGroup("h5md");
  
  H5::DataSpace dsVersion = H5::DataSpace();
  hsize_t dim = 2;
  H5::ArrayType dataType(H5::PredType::NATIVE_INT, 1, &dim);
  H5::Attribute versionAttr = h5md.createAttribute("version", dataType, dsVersion);
  int version[2] = {1, 1};
  versionAttr.write(dataType, version);


  H5::StrType strType(H5::PredType::C_S1, 5);
  H5::DataSpace ds = H5::DataSpace(H5S_SCALAR);
  H5::Group h5mdCreator = h5md.createGroup("creator");
  H5::Attribute creatorNameAttr = h5mdCreator.createAttribute("name", strType, ds);
  creatorNameAttr.write(strType, "VOTCA");

  H5::Attribute versionNameAttr = h5mdCreator.createAttribute("version", strType, ds);
  versionNameAttr.write(strType, VERSION);
}

}  // namespace csg
}  // namespace votca