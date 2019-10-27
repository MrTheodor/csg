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

#ifndef SRC_LIBCSG_MODULES_IO_H5MDTRAJECTORYWRITER_H
#define SRC_LIBCSG_MODULES_IO_H5MDTRAJECTORYWRITER_H

#include <votca/csg/trajectorywriter.h>
#include <votca_config.h>
#include "h5md.h"

#include "H5Cpp.h"

namespace votca {
namespace csg {

/**
 * \brief class for writing H5MD trajectory
 *
 * This class implements the H5MD trajectory writer function. The format of
   the H5MD file is defined in Pierre de Buyl, Peter H. Colberg, Felix Höfling,
   H5MD: A structured, efficient, and portable file format for molecular data,
   http://dx.doi.org/10.1016/j.cpc.2014.01.018 The current reference is
   available here: http://nongnu.org/h5md/
 */

class H5MDTrajectoryWriter : public TrajectoryWriter, public H5MDReadWrite {
 public:
  H5MDTrajectoryWriter();
  ~H5MDTrajectoryWriter() override;
  void Open(std::string file, bool bAppend = false) override;
  void Close() override;
  void Write(Topology *conf) override;

 private:
  void Initialize(Topology *top);
  bool appendMode;
  bool fileOpened_;
  bool newFile_;
  void initializeHeader();
  void initializeTimeGroup(const string& name);
  H5::H5File hdfFile_;
  H5::Group particleGroup_;
};

}  // namespace csg
}  // namespace votca

#endif //SRC_LIBCSG_MODULES_IO_H5MDTRAJECTORYWRITER_H
