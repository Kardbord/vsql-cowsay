/* Copyright (c) 2026 VillageSQL Contributors
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <https://www.gnu.org/licenses/>.
 */

#include <cstring>
#include <string_view>
#include <villagesql/vsql.h>

constexpr size_t BUF_SIZE = 2048;

constexpr std::string_view COW_ART{R"(
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
)"};

void cowsay_impl(vsql::StringArg in, vsql::StringResult out) {
  if (in.value().size() + COW_ART.size() > BUF_SIZE) {
    out.error("input is too large for cowsay :(");
    return;
  }

  size_t written = 0;
  if (!in.is_null()) {
    std::memcpy(out.buffer().data(), in.value().data(), in.value().size());
    written += in.value().size();
  }

  std::memcpy(out.buffer().data() + written, COW_ART.data(), COW_ART.size());
  written += COW_ART.size();
  out.set_length(written);
}

VEF_GENERATE_ENTRY_POINTS(
    make_extension().func(make_func<&cowsay_impl>("cowsay")
                              .returns(STRING)
                              .param(STRING)
                              .deterministic()
                              .buffer_size(BUF_SIZE)
                              .build()))
