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

#ifndef SRC_LIBCSG_MODULES_IO_H5MD_H_
#define SRC_LIBCSG_MODULES_IO_H5MD_H_

#include <string>
#include <stdexcept>
#include "H5Cpp.h"

namespace votca {
namespace csg {

class H5MDReadWrite {
 protected:

  /**
   * Get the HDF5 Group if exists or create and return the new group
   * @param name string with the path to the group
   * @param loc HDF5 location
   * @return a valid group identifiers for the open group if successful; otherwise throws an exception.
   */
  H5::Group GetOrCreateGroup(const std::string& name, const H5::H5Location& loc) {
    if(!loc.exists(name, H5P_DEFAULT)) {
      return loc.createGroup(name);
    } else {
      return loc.openGroup(name);
    }
  }
};


}
}

#endif //SRC_LIBCSG_MODULES_IO_H5MD_H_
