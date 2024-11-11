package main

import (
	"context"
	"crypto/tls"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func (app *application) serve() error {
	tlsConfig := &tls.Config{
		CurvePreferences: []tls.CurveID{tls.X25519, tls.CurveP256},
	}

	srv := &http.Server{
		Addr:         *app.addr,
		ErrorLog:     app.errorLog,
		Handler:      app.routes(),
		TLSConfig:    tlsConfig,
		IdleTimeout:  time.Minute,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
	}

	shutdownError := make(chan error)

	//graceful shutdown
	go func() {
		quit := make(chan os.Signal, 1)

		signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

		s := <-quit
		app.infoLog.Printf("Caught signal %s, shutting down server...", s)

		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		err := srv.Shutdown(ctx)
		if err != nil {
			shutdownError <- err
		}

		app.infoLog.Printf("completing background tasks")

		app.wg.Wait()
		shutdownError <- nil
	}()

	app.infoLog.Printf("Starting server on %s", *app.addr)
	err := srv.ListenAndServeTLS("./tls/cert.pem", "./tls/key.pem")
	if err != nil {
		return err
	}

	err = <-shutdownError
	if err != nil {
		return err
	}

	app.infoLog.Printf("Server stoped")

	return nil
}
