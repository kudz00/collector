/** collector

A full notice with attributions is provided along with this source code.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License version 2 as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

* In addition, as a special exception, the copyright holders give
* permission to link the code of portions of this program with the
* OpenSSL library under certain conditions as described in each
* individual source file, and distribute linked combinations
* including the two.
* You must obey the GNU General Public License in all respects
* for all of the code used other than OpenSSL.  If you modify
* file(s) with this exception, you may extend this exception to your
* version of the file(s), but you are not obligated to do so.  If you
* do not wish to do so, delete this exception statement from your
* version.
*/

#ifndef __SIGNAL_SERVICE_CLIENT_H
#define __SIGNAL_SERVICE_CLIENT_H

// SIGNAL_SERVICE_CLIENT.h
// This class defines our GRPC client abstraction

#include "SafeBuffer.h"
#include "CollectorService.h"

#include <grpc/grpc.h>
#include <grpcpp/channel.h>
#include <grpcpp/client_context.h>
#include <grpcpp/create_channel.h>
#include <grpcpp/security/credentials.h>

#include "../generated/proto/api/private/signal-service/signal_service.pb.h"
#include "../generated/proto/api/private/signal-service/signal_service.grpc.pb.h"

using grpc::Channel;
using grpc::ClientContext;
using grpc::ClientReader;
using grpc::ClientReaderWriter;
using grpc::ClientWriter;
using grpc::Status;
using signal_service::SignalService;
using signal_service::Empty;

namespace collector {

struct GRPCServerOptions {
  std::string server_endpoint = ""; // localhost:10000
  grpc::string pem_cert_chain = "";
  grpc::string pem_private_key = "";
  grpc::string pem_root_certs = "";
};

class SignalServiceClient {
 public:
  void CreateGRPCStub(const gRPCConfig& config);
  ~SignalServiceClient() {};

  bool PushSignals(const SafeBuffer& buffer);
 private:
  signal_service::Empty empty;
  ClientContext context;

  std::shared_ptr<grpc::Channel> channel_;
  std::unique_ptr<SignalService::Stub> stub_;
  signal_service::SignalStreamMessage signal_stream_;
  std::unique_ptr<ClientWriter<signal_service::SignalStreamMessage> > grpc_writer_;
};


}  // namespace collector

#endif // __SIGNAL_SERVICE_CLIENT_H
