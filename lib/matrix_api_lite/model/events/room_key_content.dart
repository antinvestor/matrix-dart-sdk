/* MIT License
* 
* Copyright (C) 2019, 2020, 2021 Famedly GmbH
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import 'package:matrix/matrix_api_lite/model/basic_event.dart';
import 'package:matrix/matrix_api_lite/utils/try_get_map_extension.dart';

extension RoomKeyContentBasicEventExtension on BasicEvent {
  RoomKeyContent get parsedRoomKeyContent => RoomKeyContent.fromJson(content);
}

class RoomKeyContent {
  String algorithm;
  String roomId;
  String sessionId;
  String sessionKey;

  RoomKeyContent({
    required this.algorithm,
    required this.roomId,
    required this.sessionId,
    required this.sessionKey,
  });

  RoomKeyContent.fromJson(Map<String, Object?> json)
    : algorithm = json.tryGet('algorithm', TryGet.required) ?? '',
      roomId = json.tryGet('room_id', TryGet.required) ?? '',
      sessionId = json.tryGet('session_id', TryGet.required) ?? '',
      sessionKey = json.tryGet('session_key', TryGet.required) ?? '';

  Map<String, Object?> toJson() {
    final data = <String, Object?>{};
    data['algorithm'] = algorithm;
    data['room_id'] = roomId;
    data['session_id'] = sessionId;
    data['session_key'] = sessionKey;
    return data;
  }
}
