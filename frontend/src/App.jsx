import { useEffect, useState } from "react";
import NoteForm from "./components/NoteForm";
import NoteList from "./components/NoteList";

const API_URL = "/api/notes/"

function App() {
  const [notes, setNotes] = useState([]);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    async function fetchNotes() {
      try {
        setIsLoading(true);
        setError("");

        const response = await fetch(API_URL);

        if (!response.ok) {
          throw new Error("Не удалось получить заметки");
        }

        const data = await response.json();

        setNotes(data);
      } catch (error) {
        setError(error.message)
      } finally {
        setIsLoading(false);
      }
    }

    fetchNotes();
  }, [])

  async function addNote(noteData) {
    try {
      setError("");

      const response = await fetch(API_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(noteData),
      });

      if (!response.ok) {
        throw new Error("Не удалось создать заметку");
      }

      const createdNote = await response.json();

      setNotes((currentNotes) => [
        ...currentNotes,
        createdNote,
      ]);

      setIsFormOpen(false);
    } catch (error) {
      setError(error.message);
    }
  }

  async function deleteNote(noteId) {
    try {
      setError("");

      const response = await fetch(`${API_URL}${noteId}/`, {
        method: "DELETE",
      });

      if (!response.ok) {
        throw new Error("Не удалось удалить заметку");
      }

      setNotes((currentNotes) =>
        currentNotes.filter((note) => note.id !== noteId)
      );
    } catch (error) {
      setError(error.message);
    }
  }

  return (
    <div className="min-h-screen bg-[#0F1115] px-6 py-10 text-[#F1F5F9]">
      <main className="mx-auto max-w-6xl">

        {/* Header */}
        <div className="mb-8 flex items-center justify-between">
          <h1 className="text-3xl font-bold">
            Мои заметки
          </h1>

          <button
            onClick={() => setIsFormOpen(true)}
            className="
              cursor-pointer
              rounded-xl
              bg-[#60A5FA]
              px-5
              py-3
              font-medium
              text-[#0F1115]
              transition
              hover:bg-[#93C5FD]
            "
          >
            + Новая заметка
          </button>
        </div>

        {/* Error */}
        {error && (
          <div
            className="
              mb-6
              rounded-xl
              border
              border-red-500/30
              bg-red-500/10
              px-4
              py-3
              text-red-400
            "
          >
            {error}
          </div>
        )}

        {/* Loading */}
        {isLoading ? (
          <p className="text-[#64748B]">
            Загрузка заметок...
          </p>
        ) : notes.length === 0 ? (
          <p className="text-[#64748B]">
            Пока нет заметок
          </p>
        ) : (
          <NoteList
            notes={notes}
            onDelete={deleteNote}
          />
        )}

      </main>

      {/* Modal */}
      {isFormOpen && (
        <NoteForm
          onClose={() => setIsFormOpen(false)}
          onAdd={addNote}
        />
      )}
    </div>
  );
}

export default App;
