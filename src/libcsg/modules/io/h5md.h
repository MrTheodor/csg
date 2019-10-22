//
// Created by teodor on 22.10.2019.
//

#ifndef SRC_LIBCSG_MODULES_IO_H5MD_H_
#define SRC_LIBCSG_MODULES_IO_H5MD_H_

#include <string>
#include <stdexcept>
#include "hdf5.h"

namespace votca {
namespace csg {

class H5MDReadWrite {
 public:
  void CheckError(hid_t hid, std::string error_message) {
    if (hid < 0) {
      // H5Eprint(H5E_DEFAULT, stderr);
      throw std::runtime_error(error_message);
    }
  }

  bool GroupExists(hid_t file_id, std::string path) {
    H5G_stat_t info;
    herr_t status = H5Gget_objinfo(file_id, path.c_str(), 0, &info);
    if (status < 0) {
      return false;
    }
    return info.type == H5G_GROUP;
  }
};

}
}

#endif //SRC_LIBCSG_MODULES_IO_H5MD_H_
