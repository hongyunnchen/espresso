/*
  Copyright (C) 2010,2011,2012,2013,2014 The ESPResSo project
  Copyright (C) 2002,2003,2004,2005,2006,2007,2008,2009,2010
  Max-Planck-Institute for Polymer Research, Theory Group

  This file is part of ESPResSo.

  ESPResSo is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  ESPResSo is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef SCRIPT_INTERFACE_OBSERVABLES_OBSERVABLE_HPP
#define SCRIPT_INTERFACE_OBSERVABLES_OBSERVABLE_HPP

#include "ScriptInterface.hpp"
#include "core/utils/Factory.hpp"

#include <memory>


#include "core/observables/Observable.hpp"
#include "core/observables/Observable.hpp"

namespace ScriptInterface {
namespace Observables {


typedef ::Observables::Observable CoreObs;

class Observable : public ScriptInterfaceBase {
public:
  Observable() {};
  
  const std::string name() const override { return "Observables::Observable"; }

  virtual std::shared_ptr<CoreObs> observable() {
    return m_observable;
  }
  virtual Variant call_method(std::string const &method,
                                   VariantMap const &parameters) {
    if (method == "calculate") {
      observable()->calculate();
      return observable()->last_value;
    }
    if (method == "update") {
      observable()->update();
      return observable()->last_value;
    }
    if (method == "value") {
      return observable()->last_value;
    }

     return {};
  };
  private:
    std::shared_ptr<::Observables::Observable> m_observable;
};
} /* namespace Observables */
} /* namespace ScriptInterface */

#endif
