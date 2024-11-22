/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file Main.vala
 *
 * @brief Tuner application entry point
 * 
 */
 
public static int main (string[] args) {
    Gst.init (ref args);

    var app = Tuner.Application.instance;
    return app.run (args);
}
