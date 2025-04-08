export function loadBoard(game) {
    console.log(game);
    // === WebGL Setup ===
    let canvas = document.getElementById("webgl-canvas");
    canvas.width = canvas.clientWidth;
    canvas.height = canvas.clientHeight;
    canvas.style.border = "2px solid white";
    

    let gl = canvas.getContext("webgl");
    if (!gl) {
        alert("WebGL not supported");
        return;
    }

    gl.enable(gl.BLEND);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);



    // === Load glMatrix for 3D transformations ===
    function loadScript(url, callback) {
        let script = document.createElement("script");
        script.src = url;
        script.onload = callback;
        document.head.appendChild(script);
    }

    loadScript("https://cdnjs.cloudflare.com/ajax/libs/gl-matrix/2.8.1/gl-matrix-min.js", function () {
        console.log("glMatrix Loaded");
        start3D();
    });
    //---------------------------------------------------------


    function start3D() {
        // === 3D Shader Setup ===
        //vert
        const vertexShaderSource = `
            attribute vec3 a_position;
            attribute vec2 a_texCoord;
            uniform mat4 u_matrix;
            varying vec2 v_texCoord;
            void main() {
                gl_Position = u_matrix * vec4(a_position, 1.0);
                v_texCoord = a_texCoord;
            }
        `;

        //frag
        const fragmentShaderSource = `
            precision mediump float;
            uniform sampler2D u_texture;
            uniform vec3 u_color;
            uniform bool u_useTexture;
            varying vec2 v_texCoord;

            void main() {
                if (u_useTexture) {
                    gl_FragColor = texture2D(u_texture, v_texCoord);
                } else {
                    gl_FragColor = vec4(u_color, 1.0);
                }
            }
        `;

        function createShader(gl, type, source) {
            const shader = gl.createShader(type);
            gl.shaderSource(shader, source);
            gl.compileShader(shader);
            if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
                console.log("Shader compile failed:", gl.getShaderInfoLog(shader));
                return null;
            }
            return shader;
        }

        function resizeCanvasToDisplaySize(canvas) {
            const realToCSSPixels = window.devicePixelRatio || 1;

            // Lookup the size the browser is displaying the canvas in CSS pixels
            const displayWidth = Math.floor(canvas.clientWidth * realToCSSPixels);
            const displayHeight = Math.floor(canvas.clientHeight * realToCSSPixels);

            // Check if the canvas is not the same size
            if (canvas.width !== displayWidth || canvas.height !== displayHeight) {
                canvas.width = displayWidth;
                canvas.height = displayHeight;
                gl.viewport(0, 0, canvas.width, canvas.height);

                // Update your projection matrix
                mat4.perspective(projectionMatrix, Math.PI / 3, canvas.width / canvas.height, 0.1, 10);
            }
        }


        function createProgram(gl, vShader, fShader) {
            const program = gl.createProgram();
            gl.attachShader(program, vShader);
            gl.attachShader(program, fShader);
            gl.linkProgram(program);
            if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
                console.log("Program link failed:", gl.getProgramInfoLog(program));
                return null;
            }
            return program;
        }

        const vertexShader = createShader(gl, gl.VERTEX_SHADER, vertexShaderSource);
        const fragmentShader = createShader(gl, gl.FRAGMENT_SHADER, fragmentShaderSource);
        const program = createProgram(gl, vertexShader, fragmentShader);
        gl.useProgram(program);

        // === Create Uniforms ===
        // let matrixUniform = gl.getUniformLocation(program, "u_matrix");
        let useTextureUniform = gl.getUniformLocation(program, "u_useTexture");
        let colorUniform = gl.getUniformLocation(program, "u_color");


        // === Board as a 3D Plane with texture coordinates ===
        const BOARD_SIZE = 0.95;

        const boardVertices = new Float32Array([
            -BOARD_SIZE, 0.0, -BOARD_SIZE, 0.0, 0.0,
            BOARD_SIZE, 0.0, -BOARD_SIZE, 1.0, 0.0,
            -BOARD_SIZE, 0.0, BOARD_SIZE, 0.0, 1.0,
            BOARD_SIZE, 0.0, BOARD_SIZE, 1.0, 1.0
        ]);


        const playerVertices = new Float32Array([
            // Front face
            -0.05, 0.0, 0.05, // 0
            0.05, 0.0, 0.05, // 1
            0.05, 0.1, 0.05, // 2
            -0.05, 0.1, 0.05, // 3

            // Back face
            -0.05, 0.0, -0.05, // 4
            0.05, 0.0, -0.05, // 5
            0.05, 0.1, -0.05, // 6
            -0.05, 0.1, -0.05  // 7
        ]);

        const playerIndices = new Uint16Array([
            // Front
            0, 1, 2, 0, 2, 3,
            // Back
            4, 5, 6, 4, 6, 7,
            // Left
            4, 0, 3, 4, 3, 7,
            // Right
            1, 5, 6, 1, 6, 2,
            // Top
            3, 2, 6, 3, 6, 7,
            // Bottom
            4, 5, 1, 4, 1, 0
        ]);


        function createBuffer(data) {
            let buffer = gl.createBuffer();
            gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
            gl.bufferData(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW);
            return buffer;
        }
        

        const boardBuffer = createBuffer(boardVertices);
        const playerBuffer = createBuffer(playerVertices);

        const playerIndexBuffer = gl.createBuffer();
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, playerIndexBuffer);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, playerIndices, gl.STATIC_DRAW);


        let positionAttrib = gl.getAttribLocation(program, "a_position");
        gl.enableVertexAttribArray(positionAttrib);
        gl.vertexAttribPointer(positionAttrib, 3, gl.FLOAT, false, 5 * Float32Array.BYTES_PER_ELEMENT, 0);

        let texCoordAttrib = gl.getAttribLocation(program, "a_texCoord");
        gl.enableVertexAttribArray(texCoordAttrib);
        gl.vertexAttribPointer(texCoordAttrib, 2, gl.FLOAT, false, 5 * Float32Array.BYTES_PER_ELEMENT, 3 * Float32Array.BYTES_PER_ELEMENT);

        let matrixUniform = gl.getUniformLocation(program, "u_matrix");
        let textureUniform = gl.getUniformLocation(program, "u_texture");

        // === Load the texture ===
        const texture = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, texture);

        const image = new Image();
        image.onload = function () {
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);
            gl.generateMipmap(gl.TEXTURE_2D);
        };
        image.src = '/images/board_image4.png';  // Replace with the path to your texture

        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

        // === Projection & Camera ===
        let projectionMatrix = mat4.create();
        let viewMatrix = mat4.create();
        let modelMatrix = mat4.create();
        let mvMatrix = mat4.create();
        let mvpMatrix = mat4.create();

        mat4.perspective(projectionMatrix, Math.PI / 3, canvas.width / canvas.height, 0.1, 10);
        mat4.lookAt(viewMatrix, [0, 1.5, 2.5], [0, 0, 0], [0, 1, 0]);

        // === Monopoly Board Logic ===
        function getBoardPosition(pos) {
            let step = 1.6 / 10;
            let half = 0.8;
            let height = 0.00;

            if (pos >= 1 && pos <= 10) return [-half + (pos - 1) * step, height, -half];
            if (pos >= 11 && pos <= 20) return [half, height, -half + (pos - 10) * step];
            if (pos >= 21 && pos <= 30) return [half - (pos - 20) * step, height, half];
            if (pos >= 31 && pos <= 40) return [-half, height, half - (pos - 30) * step];
            return [0, height, 0];
        }

        // === Players List ===
        let players = [
            { id: 1, position: 1, color: [1, 0, 0] },  // Red
            { id: 2, position: 10, color: [0, 1, 0] }, // Green
            { id: 3, position: 20, color: [0, 0, 1] }  // Blue
        ];

        function drawScene(playerPosition) {
            resizeCanvasToDisplaySize(canvas)
            gl.clearColor(0, 0, 0, 1);
            gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
            gl.enable(gl.DEPTH_TEST);

            // === Draw Board ===
            mat4.identity(modelMatrix);
            mat4.translate(modelMatrix, modelMatrix, [0, -0.01, 0]);
            mat4.multiply(mvMatrix, viewMatrix, modelMatrix);
            mat4.multiply(mvpMatrix, projectionMatrix, mvMatrix);
            gl.uniformMatrix4fv(matrixUniform, false, mvpMatrix);

            gl.bindBuffer(gl.ARRAY_BUFFER, boardBuffer);
            gl.vertexAttribPointer(positionAttrib, 3, gl.FLOAT, false, 5 * Float32Array.BYTES_PER_ELEMENT, 0);
            gl.vertexAttribPointer(texCoordAttrib, 2, gl.FLOAT, false, 5 * Float32Array.BYTES_PER_ELEMENT, 3 * Float32Array.BYTES_PER_ELEMENT);
            gl.uniform1i(useTextureUniform, 1); // Use texture
            gl.bindBuffer(gl.ARRAY_BUFFER, boardBuffer);
            gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

            // === Draw Players ===
            players.forEach(player => {
                let pos = getBoardPosition(player.position);

                mat4.identity(modelMatrix);
                mat4.translate(modelMatrix, modelMatrix, pos);
                mat4.multiply(mvMatrix, viewMatrix, modelMatrix);
                mat4.multiply(mvpMatrix, projectionMatrix, mvMatrix);
                gl.uniformMatrix4fv(matrixUniform, false, mvpMatrix);

                gl.bindBuffer(gl.ARRAY_BUFFER, playerBuffer);
                gl.vertexAttribPointer(positionAttrib, 3, gl.FLOAT, false, 0, 0);

                gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, playerIndexBuffer);

                gl.uniform1i(useTextureUniform, 0); // Use solid color
                gl.uniform3fv(colorUniform, player.color); // Player color

                gl.drawElements(gl.TRIANGLES, playerIndices.length, gl.UNSIGNED_SHORT, 0);
            });

        }




        // === Camera Controls ===
        let angleY = 0;
        let dragging = false;
        let lastX = 0;

        canvas.addEventListener("mousedown", (event) => {
            dragging = true;
            lastX = event.clientX;
        });

        canvas.addEventListener("mouseup", () => {
            dragging = false;
        });

        canvas.addEventListener("mousemove", (event) => {
            if (!dragging) return;

            let deltaX = event.clientX - lastX;
            lastX = event.clientX;

            // Adjust rotation speed
            let sensitivity = 0.005;
            angleY += deltaX * sensitivity;

            updateViewMatrix();
        });

        function updateViewMatrix() {
            let radius = 1.5; // Distance from the board
            let eyeX = radius * Math.sin(angleY);
            let eyeZ = radius * Math.cos(angleY);

            mat4.lookAt(viewMatrix, [eyeX, 1.5, eyeZ], [0, 0, 0], [0, 1, 0]);

            requestAnimationFrame(drawScene); // Smoothly update view
        }


        // let playerPosition = 1;
        function updatePlayers() {
            players.forEach(player => {
                player.position = (player.position % 40) + 1;
            });
            drawScene();
        }

        setInterval(updatePlayers, 1000);
    }
}
